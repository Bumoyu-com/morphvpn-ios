//
//  MorphUDPClient.swift
//  WireGuardExtension
//
//  MorphProtocol UDP 客户端
//

import Foundation
import Network

class MorphUDPClient {
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.morphvpn.udp", qos: .userInitiated)
    private let encryptor: MorphEncryptor
    private let obfuscator: MorphObfuscator
    private var isConnected = false
    
    var onReceive: ((Data) -> Void)?
    var onError: ((Error) -> Void)?
    var onStateChange: ((NWConnection.State) -> Void)?
    
    init(encryptionKey: String, obfuscationLayer: Int, paddingLength: Int) throws {
        NSLog("🔒 MorphUDPClient: Initializing...")
        self.encryptor = try MorphEncryptor(keyString: encryptionKey)
        self.obfuscator = MorphObfuscator(layer: obfuscationLayer, paddingLength: paddingLength)
        NSLog("✅ MorphUDPClient: Initialized with layer=\(obfuscationLayer), padding=\(paddingLength)")
    }
    
    func connect(host: String, port: UInt16) {
        NSLog("🔌 MorphUDPClient: Connecting to \(host):\(port)")
        
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!
        )
        
        let parameters = NWParameters.udp
        parameters.requiredInterfaceType = .wifi
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
                
                // 3. 发送
                self.connection?.send(content: obfuscated, completion: .contentProcessed { error in
                    if let error = error {
                        NSLog("❌ MorphUDPClient: Send error: \(error)")
                        self.onError?(error)
                    } else {
                        NSLog("✅ MorphUDPClient: Sent \(obfuscated.count) bytes")
                    }
                })
            } catch {
                NSLog("❌ MorphUDPClient: Encryption error: \(error)")
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
                NSLog("📦 MorphUDPClient: Received \(data.count) bytes")
                
                do {
                    // 1. 解混淆
                    let deobfuscated = self.obfuscator.deobfuscate(data)
                    NSLog("🎭 MorphUDPClient: Deobfuscated \(data.count) → \(deobfuscated.count) bytes")
                    
                    // 2. 解密
                    let decrypted = try self.encryptor.decrypt(deobfuscated)
                    NSLog("🔓 MorphUDPClient: Decrypted \(deobfuscated.count) → \(decrypted.count) bytes")
                    
                    // 3. 回调
                    self.onReceive?(decrypted)
                } catch {
                    NSLog("❌ MorphUDPClient: Decryption error: \(error)")
                    self.onError?(error)
                }
            }
            
            // 继续接收
            if self.isConnected {
                self.startReceiving()
            }
        }
    }
    
    func disconnect() {
        NSLog("🔌 MorphUDPClient: Disconnecting...")
        isConnected = false
        connection?.cancel()
        connection = nil
        NSLog("✅ MorphUDPClient: Disconnected")
    }
    
    deinit {
        disconnect()
    }
}
