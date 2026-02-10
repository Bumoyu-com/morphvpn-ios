//
//  MorphUDPClient.swift
//  MorphProtocol Plugin
//
//  MorphProtocol UDP 客户端 - 带本地 UDP 代理功能
//  使用 NWListener 监听本地端口，接收 WireGuard 数据并转发到远程服务器
//

import Foundation
import Network

class MorphUDPClient {
    // MARK: - 远程服务器连接
    private var handshakeConnection: NWConnection?  // 握手连接 (12301)
    private var dataConnection: NWConnection?       // 数据连接 (会话端口)
    
    // MARK: - 本地 UDP 代理 (NWListener)
    private var localListener: NWListener?          // 本地 UDP 监听器
    private var localPort: UInt16 = 0               // 本地监听端口
    private var wireGuardConnection: NWConnection?  // 用于回复 WireGuard 的连接
    
    // MARK: - 核心组件
    private let queue = DispatchQueue(label: "com.morphvpn.morphprotocol", qos: .userInitiated)
    private let encryptor: MorphEncryptor
    private let obfuscator: MorphObfuscator
    private let template: ProtocolTemplate?
    private let clientID: Data
    private var isConnected = false
    
    // MARK: - 配置
    private var remoteHost: String = ""
    private var remotePort: UInt16 = 0
    private var sessionPort: UInt16?
    private var userId: String = ""
    
    // MARK: - 回调
    var onReceive: ((Data) -> Void)?
    var onError: ((Error) -> Void)?
    var onStateChange: ((NWConnection.State) -> Void)?
    var onLocalPortReady: ((UInt16) -> Void)?       // 本地端口就绪回调
    var onHandshakeComplete: ((UInt16) -> Void)?    // 握手完成回调，返回会话端口
    
    // MARK: - 初始化
    
    init(encryptionKey: String, 
         obfuscationLayer: Int, 
         paddingLength: Int,
         templateType: TemplateType? = nil,
         userId: String = "") throws {
        
        NSLog("🔒 MorphUDPClient: init userId=\(userId)")
        
        self.userId = userId
        
        // 初始化加密器
        self.encryptor = try MorphEncryptor(keyString: encryptionKey)
        
        // 随机生成混淆 key（0-255），与 Android Random.nextInt(256) 对齐
        let key = Int.random(in: 0...255)
        
        // 初始化混淆器
        self.obfuscator = MorphObfuscator(
            key: key,
            layer: obfuscationLayer,
            paddingLength: paddingLength
        )
        
        // 生成客户端 ID (16 bytes)
        var clientIDData = Data(count: 16)
        for i in 0..<16 {
            clientIDData[i] = UInt8.random(in: 0...255)
        }
        self.clientID = clientIDData
        
        // 创建协议模板
        if let type = templateType {
            self.template = TemplateFactory.createTemplate(type)
            if let template = self.template {
                NSLog("🎭 MorphUDPClient: Using \(template.name) template")
            }
        } else {
            self.template = nil
            NSLog("ℹ️ MorphUDPClient: No protocol template")
        }
        
        NSLog("✅ MorphUDPClient: ready tpl=\(template?.name ?? "None")")
    }
    
    // MARK: - 启动本地 UDP 代理
    
    /// 启动本地 UDP 监听器，返回监听端口
    func startLocalProxy(preferredPort: UInt16 = 0) -> UInt16? {
        NSLog("🔌 MorphUDPClient: Starting local UDP proxy...")
        
        let parameters = NWParameters.udp
        parameters.allowLocalEndpointReuse = true
        
        do {
            // 如果指定了端口，使用指定端口；否则让系统分配
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
                        NSLog("✅ MorphUDPClient: Local proxy listening on 127.0.0.1:\(port)")
                        self.onLocalPortReady?(port)
                    }
                    
                case .failed(let error):
                    NSLog("❌ MorphUDPClient: Local listener failed: \(error)")
                    self.onError?(error)
                    
                case .cancelled:
                    NSLog("⚠️ MorphUDPClient: Local listener cancelled")
                    
                default:
                    break
                }
            }
            
            // 处理新的 UDP 连接（来自 WireGuard）
            localListener?.newConnectionHandler = { [weak self] connection in
                self?.handleNewLocalConnection(connection)
            }
            
            localListener?.start(queue: queue)
            
            // 等待端口分配
            Thread.sleep(forTimeInterval: 0.1)
            return localListener?.port?.rawValue
            
        } catch {
            NSLog("❌ MorphUDPClient: Failed to create local listener: \(error)")
            onError?(error)
            return nil
        }
    }
    
    /// 处理来自 WireGuard 的新连接
    private func handleNewLocalConnection(_ connection: NWConnection) {
        wireGuardConnection = connection
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                NSLog("✅ MorphUDPClient: WireGuard connection ready")
                self?.receiveFromWireGuard(connection)
            case .failed(let error):
                NSLog("❌ MorphUDPClient: WireGuard connection failed: \(error)")
            default:
                break
            }
        }
        
        connection.start(queue: queue)
    }
    
    /// 接收来自 WireGuard 的数据
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
    
    /// 连接到远程 MorphProtocol 服务器（旧接口兼容）
    func connect(host: String, port: UInt16) {
        connectToRemote(host: host, port: port)
    }
    
    /// 连接到远程 MorphProtocol 服务器
    func connectToRemote(host: String, port: UInt16) {
        self.remoteHost = host
        self.remotePort = port
        
        NSLog("🔌 MorphUDPClient: Connecting to remote \(host):\(port)")
        
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
                self.sendHandshake()
                
            case .failed(let error):
                NSLog("❌ MorphUDPClient: Handshake connection failed: \(error)")
                self.isConnected = false
                self.onError?(error)
                
            case .cancelled:
                NSLog("⚠️ MorphUDPClient: Handshake connection cancelled")
                self.isConnected = false
                
            default:
                break
            }
        }
        
        handshakeConnection?.start(queue: queue)
    }
    
    // MARK: - 数据转发
    
    /// 将 WireGuard 数据转发到远程服务器
    private func forwardToRemoteServer(_ data: Data) {
        guard let _ = sessionPort else {
            NSLog("⚠️ [WG→Server] Session not established")
            return
        }
        
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
    
    /// 将服务器响应转发回 WireGuard
    private func forwardToWireGuard(_ data: Data) {
        guard let connection = wireGuardConnection else {
            NSLog("⚠️ [Server→WG] No WireGuard connection")
            return
        }
        
        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                NSLog("❌ [Server→WG] Send error: \(error)")
            }
        })
    }
    
    // MARK: - 握手处理
    
    private func sendHandshake() {
        NSLog("🤝 MorphUDPClient: Sending handshake...")
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                // 构建握手数据
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
                
                // 转换为 JSON
                let jsonData = try JSONSerialization.data(withJSONObject: handshakeData)
                guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                    NSLog("❌ MorphUDPClient: Failed to convert handshake to string")
                    return
                }
                
                // 加密握手数据
                let encrypted = try self.encryptor.encrypt(Data(jsonString.utf8))
                let encryptedBase64 = encrypted.base64EncodedString()
                
                // 发送加密的握手数据
                let handshakePacket = Data(encryptedBase64.utf8)
                
                self.handshakeConnection?.send(content: handshakePacket, completion: .contentProcessed { error in
                    if let error = error {
                        NSLog("❌ MorphUDPClient: Handshake send error: \(error)")
                        self.onError?(error)
                    } else {
                        NSLog("✅ MorphUDPClient: Handshake sent successfully")
                    }
                })
                
            } catch {
                NSLog("❌ MorphUDPClient: Handshake preparation error: \(error)")
                self.onError?(error)
            }
        }
    }
    
    private func startReceivingHandshake() {
        handshakeConnection?.receiveMessage { [weak self] data, context, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                NSLog("❌ MorphUDPClient: Handshake receive error: \(error)")
                self.onError?(error)
                return
            }
            
            if let data = data, !data.isEmpty {
                if let response = self.tryParseHandshakeResponse(data) {
                    self.handleHandshakeResponse(response)
                }
            }
            
            // 继续接收（用于接收 inactivity 等消息）
            self.startReceivingHandshake()
        }
    }
    
    private func tryParseHandshakeResponse(_ data: Data) -> [String: Any]? {
        guard let base64String = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        // 检查是否是特殊消息
        if base64String == "inactivity" {
            NSLog("⚠️ MorphUDPClient: Server detected inactivity")
            return nil
        }
        
        if base64String == "server_full" {
            NSLog("⚠️ MorphUDPClient: Server is full")
            return nil
        }
        
        // Base64 解码
        guard let encryptedData = Data(base64Encoded: base64String) else {
            NSLog("🤝 Not valid base64")
            return nil
        }
        
        do {
            // 解密
            let decrypted = try encryptor.decrypt(encryptedData)
            
            guard let jsonString = String(data: decrypted, encoding: .utf8) else {
                return nil
            }
            
            NSLog("🤝 Decrypted response: \(jsonString)")
            
            // 解析 JSON
            if let json = try? JSONSerialization.jsonObject(with: decrypted) as? [String: Any] {
                if json["port"] != nil {
                    return json
                }
            }
        } catch {
            NSLog("🤝 Decrypt error: \(error)")
        }
        
        return nil
    }
    
    private func handleHandshakeResponse(_ response: [String: Any]) {
        guard let port = response["port"] as? Int else {
            NSLog("❌ MorphUDPClient: Invalid handshake response - missing port")
            return
        }
        
        let status = response["status"] as? String ?? "unknown"
        let confirmedClientID = response["clientID"] as? String ?? ""
        
        NSLog("✅ MorphUDPClient: Handshake response:")
        NSLog("   Port: \(port)")
        NSLog("   Status: \(status)")
        NSLog("   ClientID: \(confirmedClientID)")
        
        self.sessionPort = UInt16(port)
        
        // 创建到会话端口的数据连接
        createDataConnection(port: UInt16(port))
        
        // 通知握手完成
        onHandshakeComplete?(UInt16(port))
    }
    
    private func createDataConnection(port: UInt16) {
        NSLog("🔌 MorphUDPClient: Creating data connection to port \(port)")
        
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(self.remoteHost),
            port: NWEndpoint.Port(rawValue: port)!
        )
        
        let parameters = NWParameters.udp
        parameters.allowLocalEndpointReuse = true
        
        dataConnection = NWConnection(to: endpoint, using: parameters)
        
        dataConnection?.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            
            NSLog("🔌 MorphUDPClient: Data connection state: \(state)")
            
            switch state {
            case .ready:
                NSLog("✅ MorphUDPClient: Data connection ready on port \(port)")
                self.startReceivingData()
                
            case .failed(let error):
                NSLog("❌ MorphUDPClient: Data connection failed: \(error)")
                self.onError?(error)
                
            default:
                break
            }
        }
        
        dataConnection?.start(queue: queue)
    }
    
    private func startReceivingData() {
        dataConnection?.receiveMessage { [weak self] data, context, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                NSLog("❌ MorphUDPClient: Data receive error: \(error)")
                return
            }
            
            if let data = data, !data.isEmpty {
                NSLog("📥 [Server→Morph] Received \(data.count) bytes from server")
                
                // 处理服务器响应
                self.processServerResponse(data)
            }
            
            // 继续接收
            self.startReceivingData()
        }
    }
    
    /// 处理服务器响应并转发给 WireGuard
    private func processServerResponse(_ data: Data) {
        // 1. 协议解封装
        let obfuscated: Data
        if let template = self.template {
            guard let extracted = template.decapsulate(data) else {
                NSLog("❌ [Server→WG] Failed to decapsulate")
                return
            }
            obfuscated = extracted
            NSLog("📦 [Server→WG] After decapsulate: \(obfuscated.count) bytes")
        } else {
            obfuscated = data
        }
        
        // 2. 解混淆
        let deobfuscated = self.obfuscator.deobfuscate(obfuscated)
        NSLog("🎭 [Server→WG] After deobfuscate: \(deobfuscated.count) bytes")
        
        // 3. 转发给 WireGuard
        forwardToWireGuard(deobfuscated)
        
        // 4. 也通知回调（可选）
        onReceive?(deobfuscated)
    }
    
    // MARK: - 公共方法
    
    /// 手动发送数据（用于测试）
    func send(_ data: Data) {
        forwardToRemoteServer(data)
    }
    
    /// 获取本地监听端口
    func getLocalPort() -> UInt16 {
        return localPort
    }
    
    /// 获取会话端口
    func getSessionPort() -> UInt16? {
        return sessionPort
    }
    
    /// 断开连接
    func disconnect() {
        NSLog("🔌 MorphUDPClient: Disconnecting...")
        
        // 停止本地监听
        localListener?.cancel()
        localListener = nil
        
        // 关闭 WireGuard 连接
        wireGuardConnection?.cancel()
        wireGuardConnection = nil
        
        // 关闭远程连接
        handshakeConnection?.cancel()
        dataConnection?.cancel()
        handshakeConnection = nil
        dataConnection = nil
        
        isConnected = false
        sessionPort = nil
        localPort = 0
        
        NSLog("✅ MorphUDPClient: Disconnected")
    }
}
