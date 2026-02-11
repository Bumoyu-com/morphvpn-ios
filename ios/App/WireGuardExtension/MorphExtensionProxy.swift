//
//  MorphExtensionProxy.swift
//  WireGuardExtension
//
//  轻量级 MorphProtocol UDP 代理，运行在 Network Extension 进程中。
//  只做数据转发（混淆/解混淆），握手在 App 进程中完成。
//

import Foundation
import Network

class MorphExtensionProxy {
    private let queue = DispatchQueue(label: "com.morphvpn.morphproxy", qos: .userInitiated)
    
    // 本地 UDP 监听（WireGuard 发包到这里）
    private var listener: NWListener?
    private var wgConnection: NWConnection?
    
    // 远程服务器数据连接
    private var serverConnection: NWConnection?
    private let remoteHost: String
    private let remotePort: UInt16
    
    // 混淆组件
    private let obfuscator: MorphObfuscator
    private let template: ProtocolTemplate?
    private let clientID: Data
    
    init(host: String,
         sessionPort: UInt16,
         key: Int,
         layer: Int,
         padding: Int,
         templateId: Int,
         clientID: Data,
         fnInitor: [String: Any]?) throws {
        
        self.remoteHost = host
        self.remotePort = sessionPort
        self.clientID = clientID
        
        // 初始化混淆器（使用 App 进程握手时相同的 fnInitor 参数）
        if let fnInitor = fnInitor,
           let subTableInts = fnInitor["substitutionTable"] as? [Int],
           let randVal = fnInitor["randomValue"] as? Int {
            let subTable = subTableInts.map { UInt8($0 & 0xFF) }
            self.obfuscator = MorphObfuscator(
                key: key, layer: layer, paddingLength: padding,
                substitutionTable: subTable, randomValue: UInt8(randVal & 0xFF)
            )
            NSLog("🎭 MorphExtensionProxy: using App process fnInitor (subTable len=\(subTable.count), randVal=\(randVal))")
        } else {
            // fallback: 没有 fnInitor 时随机生成（不推荐，会导致混淆不一致）
            self.obfuscator = MorphObfuscator(key: key, layer: layer, paddingLength: padding)
            NSLog("⚠️ MorphExtensionProxy: no fnInitor provided, using random (may cause mismatch!)")
        }
        
        // 创建协议模板
        if let type = TemplateType(rawValue: UInt8(templateId)) {
            self.template = TemplateFactory.createTemplate(type)
        } else {
            self.template = nil
        }
        
        NSLog("🎭 MorphExtensionProxy: init host=\(host) port=\(sessionPort) key=\(key) tpl=\(template?.name ?? "None")")
    }
    
    /// 启动本地 UDP 代理，返回监听端口
    func start() -> UInt16? {
        // 1. 启动本地 UDP 监听
        let params = NWParameters.udp
        params.allowLocalEndpointReuse = true
        
        do {
            listener = try NWListener(using: params)
        } catch {
            NSLog("❌ MorphExtensionProxy: Failed to create listener: \(error)")
            return nil
        }
        
        var assignedPort: UInt16?
        let semaphore = DispatchSemaphore(value: 0)
        
        listener?.stateUpdateHandler = { state in
            SharedLog.shared.log("📡 Proxy listener state → \(state)")
            if case .ready = state {
                semaphore.signal()
            }
        }
        
        listener?.newConnectionHandler = { [weak self] connection in
            SharedLog.shared.log("📡 WireGuard connected to proxy")
            self?.handleWireGuardConnection(connection)
        }
        
        listener?.start(queue: queue)
        
        // 等待 listener ready
        _ = semaphore.wait(timeout: .now() + 2.0)
        assignedPort = listener?.port?.rawValue
        
        guard let port = assignedPort else {
            NSLog("❌ MorphExtensionProxy: Listener failed to get port")
            return nil
        }
        
        // 2. 连接到远程服务器的 session port
        connectToServer()
        
        return port
    }
    
    func stop() {
        NSLog("🔌 MorphExtensionProxy: stopping")
        listener?.cancel()
        listener = nil
        wgConnection?.cancel()
        wgConnection = nil
        serverConnection?.cancel()
        serverConnection = nil
    }
    
    // MARK: - WireGuard → Server
    
    private func handleWireGuardConnection(_ connection: NWConnection) {
        wgConnection = connection
        connection.stateUpdateHandler = { [weak self] state in
            if case .ready = state {
                NSLog("✅ MorphExtensionProxy: WireGuard connection ready")
                self?.receiveFromWireGuard(connection)
            }
        }
        connection.start(queue: queue)
    }
    
    private var wgToServerCount = 0
    private var serverToWgCount = 0
    
    private func receiveFromWireGuard(_ connection: NWConnection) {
        connection.receiveMessage { [weak self] data, _, _, error in
            guard let self = self else { return }
            if let error = error {
                SharedLog.shared.log("❌ WG recv error: \(error)")
                return
            }
            if let data = data, !data.isEmpty {
                self.forwardToServer(data)
            }
            self.receiveFromWireGuard(connection)
        }
    }
    
    private func forwardToServer(_ data: Data) {
        wgToServerCount += 1
        if wgToServerCount <= 3 || wgToServerCount % 100 == 0 {
            SharedLog.shared.log("📤 WG→Server #\(wgToServerCount) len=\(data.count)")
        }
        
        // 混淆 + 协议封装
        let obfuscated = obfuscator.obfuscate(data)
        let packet: Data
        if let template = self.template {
            packet = template.encapsulate(obfuscated, clientID: clientID)
        } else {
            packet = obfuscated
        }
        
        serverConnection?.send(content: packet, completion: .contentProcessed { error in
            if let error = error {
                SharedLog.shared.log("❌ WG→Server send error: \(error)")
            }
        })
    }
    
    // MARK: - Server → WireGuard
    
    private func connectToServer() {
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(remoteHost),
            port: NWEndpoint.Port(rawValue: remotePort)!
        )
        let params = NWParameters.udp
        params.allowLocalEndpointReuse = true
        
        SharedLog.shared.log("🔌 Connecting to server \(remoteHost):\(remotePort)")
        
        serverConnection = NWConnection(to: endpoint, using: params)
        serverConnection?.stateUpdateHandler = { [weak self] state in
            SharedLog.shared.log("📡 Server conn state → \(state)")
            if case .ready = state {
                self?.receiveFromServer()
            }
        }
        serverConnection?.start(queue: queue)
    }
    
    private func receiveFromServer() {
        serverConnection?.receiveMessage { [weak self] data, _, _, error in
            guard let self = self else { return }
            if let error = error {
                SharedLog.shared.log("❌ Server recv error: \(error)")
                return
            }
            if let data = data, !data.isEmpty {
                self.forwardToWireGuard(data)
            }
            self.receiveFromServer()
        }
    }
    
    private func forwardToWireGuard(_ data: Data) {
        serverToWgCount += 1
        if serverToWgCount <= 3 || serverToWgCount % 100 == 0 {
            SharedLog.shared.log("📥 Server→WG #\(serverToWgCount) len=\(data.count)")
        }
        
        // 协议解封装 + 解混淆
        let obfuscated: Data
        if let template = self.template {
            guard let extracted = template.decapsulate(data) else {
                SharedLog.shared.log("❌ Server→WG decapsulate failed, len=\(data.count)")
                return
            }
            obfuscated = extracted
        } else {
            obfuscated = data
        }
        
        let deobfuscated = obfuscator.deobfuscate(obfuscated)
        
        wgConnection?.send(content: deobfuscated, completion: .contentProcessed { error in
            if let error = error {
                SharedLog.shared.log("❌ Server→WG send error: \(error)")
            }
        })
    }
}
