//
//  MorphUDPClient.swift
//  MorphProtocol Plugin
//
//  MorphProtocol UDP 客户端 - 与 Android MorphUdpClient 对齐
//  功能：本地 UDP 代理、握手重试、心跳保活、不活跃检测+自动重连、断开时发送 close
//

import Foundation
import Network

// MARK: - 配置

struct MorphClientConfig {
    var heartbeatInterval: TimeInterval = 120     // 心跳间隔（秒），Android 默认 120s
    var inactivityTimeout: TimeInterval = 30      // 不活跃超时（秒），Android 默认 30s
    var maxRetries: Int = 10                      // 握手最大重试次数
    var handshakeInterval: TimeInterval = 5       // 握手重试间隔（秒）
}

class MorphUDPClient {
    // MARK: - 远程服务器连接
    private var handshakeConnection: NWConnection?
    private var dataConnection: NWConnection?
    
    // MARK: - 本地 UDP 代理
    private var localListener: NWListener?
    private var localPort: UInt16 = 0
    private var wireGuardConnection: NWConnection?
    
    // MARK: - 核心组件（可变，重连时重新生成）
    private let queue = DispatchQueue(label: "com.morphvpn.morphprotocol", qos: .userInitiated)
    private let encryptor: MorphEncryptor
    private var obfuscator: MorphObfuscator
    private var template: ProtocolTemplate?
    private var clientID: Data
    private var isConnected = false
    
    // MARK: - 配置
    private var remoteHost: String = ""
    private var remotePort: UInt16 = 0
    private var sessionPort: UInt16?
    private var userId: String = ""
    private let encryptionKey: String
    private let obfuscationLayer: Int
    private let paddingLength: Int
    let config: MorphClientConfig
    
    // MARK: - 握手重试
    private var handshakeTimer: DispatchSourceTimer?
    private var handshakeRetryCount = 0
    
    // MARK: - 心跳
    private var heartbeatTimer: DispatchSourceTimer?
    
    // MARK: - 不活跃检测
    private var inactivityTimer: DispatchSourceTimer?
    private var lastReceivedTime: Date?
    
    // MARK: - 回调
    var onReceive: ((Data) -> Void)?
    var onError: ((Error) -> Void)?
    var onStateChange: ((NWConnection.State) -> Void)?
    var onLocalPortReady: ((UInt16) -> Void)?
    var onHandshakeComplete: ((UInt16) -> Void)?
    
    // MARK: - 初始化
    
    init(encryptionKey: String,
         obfuscationLayer: Int,
         paddingLength: Int,
         templateType: TemplateType? = nil,
         userId: String = "",
         config: MorphClientConfig = MorphClientConfig()) throws {
        
        self.userId = userId
        self.encryptionKey = encryptionKey
        self.obfuscationLayer = obfuscationLayer
        self.paddingLength = paddingLength
        self.config = config
        
        // 初始化加密器
        self.encryptor = try MorphEncryptor(keyString: encryptionKey)
        
        // 随机生成混淆 key（0-255），与 Android Random.nextInt(256) 对齐
        let key = Int.random(in: 0...255)
        self.obfuscator = MorphObfuscator(key: key, layer: obfuscationLayer, paddingLength: paddingLength)
        
        // 生成客户端 ID (16 bytes)
        var clientIDData = Data(count: 16)
        for i in 0..<16 { clientIDData[i] = UInt8.random(in: 0...255) }
        self.clientID = clientIDData
        
        // 随机选择协议模板（与 Android TemplateSelector 对齐）
        if let type = templateType {
            self.template = TemplateFactory.createTemplate(type)
        } else {
            self.template = TemplateFactory.createRandomTemplate()
        }
        
        NSLog("✅ MorphUDPClient: ready tpl=\(template?.name ?? "None") key=\(key)")
    }
    
    // MARK: - 启动本地 UDP 代理
    
    func startLocalProxy(preferredPort: UInt16 = 0) -> UInt16? {
        let parameters = NWParameters.udp
        parameters.allowLocalEndpointReuse = true
        // 强制绑定到 loopback 接口，确保 wireguard-go 发往 127.0.0.1 的包能到达
        parameters.requiredInterfaceType = .loopback
        
        do {
            if preferredPort > 0 {
                localListener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: preferredPort)!)
            } else {
                localListener = try NWListener(using: parameters)
            }
            
            localListener?.stateUpdateHandler = { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .ready:
                    if let port = self.localListener?.port?.rawValue {
                        self.localPort = port
                        NSLog("✅ MorphUDPClient: proxy on 127.0.0.1:\(port)")
                        self.onLocalPortReady?(port)
                    }
                case .failed(let error):
                    NSLog("❌ MorphUDPClient: listener failed: \(error)")
                    self.onError?(error)
                default: break
                }
            }
            
            localListener?.newConnectionHandler = { [weak self] connection in
                self?.handleNewLocalConnection(connection)
            }
            
            localListener?.start(queue: queue)
            Thread.sleep(forTimeInterval: 0.1)
            return localListener?.port?.rawValue
            
        } catch {
            NSLog("❌ MorphUDPClient: Failed to create listener: \(error)")
            onError?(error)
            return nil
        }
    }
    
    private func handleNewLocalConnection(_ connection: NWConnection) {
        wireGuardConnection = connection
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                NSLog("✅ MorphUDPClient: WireGuard connection ready")
                self?.receiveFromWireGuard(connection)
            case .failed(let error):
                NSLog("❌ MorphUDPClient: WireGuard connection failed: \(error)")
            default: break
            }
        }
        connection.start(queue: queue)
    }
    
    private func receiveFromWireGuard(_ connection: NWConnection) {
        connection.receiveMessage { [weak self] data, context, isComplete, error in
            guard let self = self else { return }
            if let error = error {
                NSLog("❌ [WG→Morph] Receive error: \(error)")
                return
            }
            if let data = data, !data.isEmpty {
                self.forwardToRemoteServer(data)
            }
            self.receiveFromWireGuard(connection)
        }
    }
    
    // MARK: - 连接远程服务器
    
    func connect(host: String, port: UInt16) {
        connectToRemote(host: host, port: port)
    }
    
    func connectToRemote(host: String, port: UInt16) {
        self.remoteHost = host
        self.remotePort = port
        
        NSLog("🔌 MorphUDPClient: Connecting to \(host):\(port)")
        
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!
        )
        
        let parameters = NWParameters.udp
        parameters.allowLocalEndpointReuse = true
        
        handshakeConnection = NWConnection(to: endpoint, using: parameters)
        
        handshakeConnection?.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            self.onStateChange?(state)
            
            switch state {
            case .ready:
                NSLog("✅ MorphUDPClient: Handshake connection ready")
                self.isConnected = true
                self.startReceivingHandshake()
                self.startHandshakeRetry()
                
            case .failed(let error):
                NSLog("❌ MorphUDPClient: Handshake connection failed: \(error)")
                self.isConnected = false
                self.onError?(error)
                
            case .cancelled:
                self.isConnected = false
                
            default: break
            }
        }
        
        handshakeConnection?.start(queue: queue)
    }
    
    // MARK: - 握手重试（P1-1）
    
    private func startHandshakeRetry() {
        stopHandshakeRetry()
        handshakeRetryCount = 0
        
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(
            deadline: .now(),
            repeating: config.handshakeInterval,
            leeway: .milliseconds(100)
        )
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            if self.sessionPort != nil {
                self.stopHandshakeRetry()
                return
            }
            
            self.sendHandshake()
            self.handshakeRetryCount += 1
            
            if self.handshakeRetryCount >= self.config.maxRetries {
                NSLog("❌ MorphUDPClient: Max handshake retries (\(self.config.maxRetries)) reached")
                self.stopHandshakeRetry()
                self.onError?(MorphError.connectionFailed)
            }
        }
        timer.resume()
        handshakeTimer = timer
    }
    
    private func stopHandshakeRetry() {
        handshakeTimer?.cancel()
        handshakeTimer = nil
    }
    
    // MARK: - 心跳机制（P1-2）
    
    private func startHeartbeat() {
        stopHeartbeat()
        
        NSLog("💓 Heartbeat started, interval=\(config.heartbeatInterval)s")
        
        // 立即发送第一次心跳
        sendHeartbeat()
        
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(
            deadline: .now() + config.heartbeatInterval,
            repeating: config.heartbeatInterval,
            leeway: .seconds(1)
        )
        timer.setEventHandler { [weak self] in
            guard let self = self, self.sessionPort != nil else { return }
            self.sendHeartbeat()
        }
        timer.resume()
        heartbeatTimer = timer
    }
    
    private func stopHeartbeat() {
        heartbeatTimer?.cancel()
        heartbeatTimer = nil
    }
    
    /// 发送心跳包：0x01 marker + 协议封装（与 Android sendHeartbeat 对齐）
    private func sendHeartbeat() {
        guard let template = self.template else { return }
        
        let heartbeatMarker = Data([0x01])
        let packet = template.encapsulate(heartbeatMarker, clientID: clientID)
        
        dataConnection?.send(content: packet, completion: .contentProcessed { error in
            if let error = error {
                NSLog("❌ Heartbeat send error: \(error)")
            }
        })
    }
    
    // MARK: - 不活跃检测 + 自动重连（P1-3）
    
    private func startInactivityCheck() {
        stopInactivityCheck()
        lastReceivedTime = Date()
        
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 90, repeating: 90, leeway: .seconds(1))
        timer.setEventHandler { [weak self] in
            guard let self = self, self.sessionPort != nil else { return }
            self.checkInactivity()
        }
        timer.resume()
        inactivityTimer = timer
    }
    
    private func stopInactivityCheck() {
        inactivityTimer?.cancel()
        inactivityTimer = nil
    }
    
    private func checkInactivity() {
        guard let lastTime = lastReceivedTime else { return }
        
        let elapsed = Date().timeIntervalSince(lastTime)
        if elapsed > config.inactivityTimeout {
            NSLog("⚠️ Inactivity detected (\(Int(elapsed))s), reconnecting...")
            reconnectWithNewParams()
        }
    }
    
    /// 重连：生成新 clientID、新模板、新混淆参数，重建连接并重新握手
    private func reconnectWithNewParams() {
        stopHeartbeat()
        stopInactivityCheck()
        stopHandshakeRetry()
        
        // 关闭旧的数据连接和握手连接
        dataConnection?.cancel()
        dataConnection = nil
        handshakeConnection?.cancel()
        handshakeConnection = nil
        sessionPort = nil
        
        // 生成新 clientID
        var newID = Data(count: 16)
        for i in 0..<16 { newID[i] = UInt8.random(in: 0...255) }
        clientID = newID
        
        // 选择新协议模板
        template = TemplateFactory.createRandomTemplate()
        
        // 生成新混淆参数
        let newKey = Int.random(in: 0...255)
        obfuscator = MorphObfuscator(key: newKey, layer: obfuscationLayer, paddingLength: paddingLength)
        
        NSLog("🔄 Reconnecting: tpl=\(template?.name ?? "None") key=\(newKey)")
        
        // 重建握手连接（不能复用已 failed/cancelled 的 NWConnection）
        connectToRemote(host: remoteHost, port: remotePort)
    }
    
    // MARK: - 数据转发
    
    private func forwardToRemoteServer(_ data: Data) {
        guard sessionPort != nil else { return }
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let obfuscated = self.obfuscator.obfuscate(data)
            let packet: Data
            if let template = self.template {
                packet = template.encapsulate(obfuscated, clientID: self.clientID)
            } else {
                packet = obfuscated
            }
            
            self.dataConnection?.send(content: packet, completion: .contentProcessed { error in
                if let error = error {
                    NSLog("❌ [WG→Server] Send error: \(error)")
                    self.onError?(error)
                }
            })
        }
    }
    
    private func forwardToWireGuard(_ data: Data) {
        guard let connection = wireGuardConnection else { return }
        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                NSLog("❌ [Server→WG] Send error: \(error)")
            }
        })
    }
    
    // MARK: - 握手处理
    
    private func sendHandshake() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                let handshakeData: [String: Any] = [
                    "clientID": self.clientID.base64EncodedString(),
                    "userId": self.userId,
                    "key": self.obfuscator.key,
                    "obfuscationLayer": self.obfuscator.layer,
                    "randomPadding": self.obfuscator.paddingLength,
                    "fnInitor": [
                        "substitutionTable": self.obfuscator.getSubstitutionTable(),
                        "randomValue": self.obfuscator.getRandomValue()
                    ],
                    "templateId": self.template?.id ?? 0,
                    "templateParams": self.template?.getParams() ?? [:],
                    "publicKey": ""
                ]
                
                let jsonData = try JSONSerialization.data(withJSONObject: handshakeData)
                guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
                
                let encrypted = try self.encryptor.encrypt(Data(jsonString.utf8))
                let handshakePacket = Data(encrypted.base64EncodedString().utf8)
                
                self.handshakeConnection?.send(content: handshakePacket, completion: .contentProcessed { error in
                    if let error = error {
                        NSLog("❌ Handshake send error: \(error)")
                        self.onError?(error)
                    } else {
                        NSLog("✅ Handshake sent (\(self.handshakeRetryCount + 1)/\(self.config.maxRetries))")
                    }
                })
            } catch {
                NSLog("❌ Handshake error: \(error)")
                self.onError?(error)
            }
        }
    }
    
    private func startReceivingHandshake() {
        handshakeConnection?.receiveMessage { [weak self] data, context, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                NSLog("❌ Handshake receive error: \(error)")
                self.onError?(error)
                return
            }
            
            if let data = data, !data.isEmpty {
                if let response = self.tryParseHandshakeResponse(data) {
                    self.handleHandshakeResponse(response)
                }
            }
            
            self.startReceivingHandshake()
        }
    }
    
    private func tryParseHandshakeResponse(_ data: Data) -> [String: Any]? {
        guard let base64String = String(data: data, encoding: .utf8) else { return nil }
        
        // 特殊消息（与 Android handleHandshakeResponse 对齐）
        if base64String == "inactivity" {
            NSLog("⚠️ Server detected inactivity")
            reconnectWithNewParams()
            return nil
        }
        
        if base64String == "server_full" {
            NSLog("⚠️ Server is full")
            onError?(MorphError.connectionFailed)
            return nil
        }
        
        guard let encryptedData = Data(base64Encoded: base64String) else { return nil }
        
        do {
            let decrypted = try encryptor.decrypt(encryptedData)
            guard let jsonString = String(data: decrypted, encoding: .utf8) else { return nil }
            NSLog("🤝 Handshake response: \(jsonString)")
            
            if let json = try? JSONSerialization.jsonObject(with: decrypted) as? [String: Any],
               json["port"] != nil {
                return json
            }
        } catch {
            NSLog("🤝 Decrypt error: \(error)")
        }
        
        return nil
    }
    
    private func handleHandshakeResponse(_ response: [String: Any]) {
        guard let port = response["port"] as? Int else {
            NSLog("❌ Invalid handshake response - missing port")
            return
        }
        
        let status = response["status"] as? String ?? "unknown"
        NSLog("✅ Handshake complete: port=\(port) status=\(status)")
        
        self.sessionPort = UInt16(port)
        
        stopHandshakeRetry()
        createDataConnection(port: UInt16(port))
        startHeartbeat()
        startInactivityCheck()
        onHandshakeComplete?(UInt16(port))
    }
    
    private func createDataConnection(port: UInt16) {
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(self.remoteHost),
            port: NWEndpoint.Port(rawValue: port)!
        )
        
        let parameters = NWParameters.udp
        parameters.allowLocalEndpointReuse = true
        
        dataConnection = NWConnection(to: endpoint, using: parameters)
        
        dataConnection?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                NSLog("✅ Data connection ready on port \(port)")
                self?.startReceivingData()
            case .failed(let error):
                NSLog("❌ Data connection failed: \(error)")
                self?.onError?(error)
            default: break
            }
        }
        
        dataConnection?.start(queue: queue)
    }
    
    private func startReceivingData() {
        dataConnection?.receiveMessage { [weak self] data, context, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                NSLog("❌ Data receive error: \(error)")
                return
            }
            
            if let data = data, !data.isEmpty {
                self.lastReceivedTime = Date()
                self.processServerResponse(data)
            }
            
            self.startReceivingData()
        }
    }
    
    private func processServerResponse(_ data: Data) {
        let obfuscated: Data
        if let template = self.template {
            guard let extracted = template.decapsulate(data) else { return }
            obfuscated = extracted
        } else {
            obfuscated = data
        }
        
        let deobfuscated = self.obfuscator.deobfuscate(obfuscated)
        
        forwardToWireGuard(deobfuscated)
        onReceive?(deobfuscated)
    }
    
    // MARK: - 公共方法
    
    func send(_ data: Data) {
        forwardToRemoteServer(data)
    }
    
    func getLocalPort() -> UInt16 {
        return localPort
    }
    
    func getSessionPort() -> UInt16? {
        return sessionPort
    }
    
    /// 断开连接（P1-4：发送加密 close 消息）
    func disconnect() {
        NSLog("🔌 MorphUDPClient: Disconnecting...")
        
        stopHandshakeRetry()
        stopHeartbeat()
        stopInactivityCheck()
        
        // 发送 close 消息到握手服务器
        sendCloseMessage()
        
        localListener?.cancel()
        localListener = nil
        wireGuardConnection?.cancel()
        wireGuardConnection = nil
        handshakeConnection?.cancel()
        dataConnection?.cancel()
        handshakeConnection = nil
        dataConnection = nil
        
        isConnected = false
        sessionPort = nil
        localPort = 0
        
        NSLog("✅ MorphUDPClient: Disconnected")
    }
    
    private func sendCloseMessage() {
        do {
            let encrypted = try encryptor.encrypt(Data("close".utf8))
            let closePacket = Data(encrypted.base64EncodedString().utf8)
            
            handshakeConnection?.send(content: closePacket, completion: .contentProcessed { error in
                if let error = error {
                    NSLog("⚠️ Close message send error: \(error)")
                }
            })
            Thread.sleep(forTimeInterval: 0.1)
        } catch {
            NSLog("⚠️ Close message encrypt error: \(error)")
        }
    }
}
