//
//  MorphUDPClient.swift
//  MorphProtocol Plugin
//
//  MorphProtocol UDP 客户端 - 完整实现
//

import Foundation
import Network

enum MorphError: Error {
    case connectionFailed
    case encryptionFailed
    case decryptionFailed
}

class MorphUDPClient {
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.morphvpn.morphprotocol", qos: .userInitiated)
    private let encryptor: MorphEncryptor
    private let obfuscator: MorphObfuscator
    private let template: ProtocolTemplate?
    private let clientID: Data
    private var isConnected = false
    
    var onReceive: ((Data) -> Void)?
    var onError: ((Error) -> Void)?
    var onStateChange: ((NWConnection.State) -> Void)?
    
    init(encryptionKey: String, 
         obfuscationLayer: Int, 
         paddingLength: Int,
         templateType: TemplateType? = nil) throws {
        
        NSLog("🔒 MorphUDPClient: Initializing...")
        
        // 初始化加密器
        self.encryptor = try MorphEncryptor(keyString: encryptionKey)
        
        // 从加密密钥派生混淆 key
        let keyData = Data(encryptionKey.utf8)
        let key = keyData.reduce(0) { $0 ^ Int($1) }
        
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
        
        NSLog("✅ MorphUDPClient: Initialized")
        NSLog("   Layer: \(obfuscationLayer)")
        NSLog("   Padding: \(paddingLength)")
        NSLog("   Template: \(template?.name ?? "None")")
    }
    
    func connect(host: String, port: UInt16) {
        NSLog("🔌 MorphUDPClient: Connecting to \(host):\(port)")
        
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!
        )
        
        let parameters = NWParameters.udp
        parameters.allowLocalEndpointReuse = true
        
        connection = NWConnection(to: endpoint, using: parameters)
        
        connection?.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            
            NSLog("🔌 MorphUDPClient: State changed to \(state)")
            self.onStateChange?(state)
            
            switch state {
            case .ready:
                NSLog("✅ MorphUDPClient: Connection ready")
                self.isConnected = true
                self.startReceiving()
                
            case .failed(let error):
                NSLog("❌ MorphUDPClient: Connection failed: \(error)")
                self.isConnected = false
                self.onError?(error)
                
            case .cancelled:
                NSLog("⚠️ MorphUDPClient: Connection cancelled")
                self.isConnected = false
                
            case .waiting(let error):
                NSLog("⏳ MorphUDPClient: Waiting: \(error)")
                
            default:
                break
            }
        }
        
        connection?.start(queue: queue)
    }
    
    func disconnect() {
        NSLog("🔌 MorphUDPClient: Disconnecting...")
        connection?.cancel()
        connection = nil
        isConnected = false
    }
    
    func send(_ data: Data) {
        guard isConnected else {
            NSLog("❌ MorphUDPClient: Not connected, cannot send")
            onError?(MorphError.connectionFailed)
            return
        }
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                // 1. 加密
                let encrypted = try self.encryptor.encrypt(data)
                NSLog("🔐 MorphUDPClient: Encrypted \(data.count) → \(encrypted.count) bytes")
                
                // 2. 混淆
                let obfuscated = self.obfuscator.obfuscate(encrypted)
                NSLog("🎭 MorphUDPClient: Obfuscated \(encrypted.count) → \(obfuscated.count) bytes")
                
                // 3. 协议封装（如果启用）
                let packet: Data
                if let template = self.template {
                    packet = template.encapsulate(obfuscated, clientID: self.clientID)
                    NSLog("📦 MorphUDPClient: Encapsulated with \(template.name): \(obfuscated.count) → \(packet.count) bytes")
                } else {
                    packet = obfuscated
                }
                
                // 4. 发送
                self.connection?.send(content: packet, completion: .contentProcessed { error in
                    if let error = error {
                        NSLog("❌ MorphUDPClient: Send error: \(error)")
                        self.onError?(error)
                    } else {
                        NSLog("✅ MorphUDPClient: Sent \(packet.count) bytes")
                    }
                })
                
            } catch {
                NSLog("❌ MorphUDPClient: Processing error: \(error)")
                self.onError?(error)
            }
        }
    }
    
    private func startReceiving() {
        connection?.receiveMessage { [weak self] data, context, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                NSLog("❌ MorphUDPClient: Receive error: \(error)")
                self.onError?(error)
                return
            }
            
            if let data = data, !data.isEmpty {
                NSLog("📥 MorphUDPClient: Received \(data.count) bytes")
                
                do {
                    // 1. 协议解封装（如果启用）
                    let obfuscated: Data
                    if let template = self.template {
                        guard let extracted = template.decapsulate(data) else {
                            NSLog("❌ MorphUDPClient: Failed to decapsulate packet")
                            return
                        }
                        obfuscated = extracted
                        NSLog("📦 MorphUDPClient: Decapsulated with \(template.name): \(data.count) → \(obfuscated.count) bytes")
                    } else {
                        obfuscated = data
                    }
                    
                    // 2. 解混淆
                    let encrypted = self.obfuscator.deobfuscate(obfuscated)
                    NSLog("🎭 MorphUDPClient: Deobfuscated \(obfuscated.count) → \(encrypted.count) bytes")
                    
                    // 3. 解密
                    let decrypted = try self.encryptor.decrypt(encrypted)
                    NSLog("🔐 MorphUDPClient: Decrypted \(encrypted.count) → \(decrypted.count) bytes")
                    
                    // 4. 回调
                    self.onReceive?(decrypted)
                    
                } catch {
                    NSLog("❌ MorphUDPClient: Processing error: \(error)")
                    self.onError?(error)
                }
            }
            
            // 继续接收
            self.startReceiving()
        }
    }
}
