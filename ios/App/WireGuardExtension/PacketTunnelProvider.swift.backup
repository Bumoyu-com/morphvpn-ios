import NetworkExtension
import WireGuardKit
import os.log

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    private var adapter: WireGuardAdapter?
    private var morphClient: MorphUDPClient?
    private lazy var logger = Logger(subsystem: "com.morphvpn.app.WireGuardExtension", category: "PacketTunnel")
    
    override init() {
        super.init()
        // 使用 NSLog 确保日志一定会输出
        NSLog("🎯 PacketTunnelProvider: init() called")
        logger.info("🎯 PacketTunnelProvider: Initialized")
    }
    
    override func startTunnel(options: [String : NSObject]?, 
                            completionHandler: @escaping (Error?) -> Void) {
        
        // 使用 NSLog 确保日志一定会输出到系统日志
        NSLog("🚀 PacketTunnelProvider: startTunnel() called")
        logger.info("🚀 Starting WireGuard tunnel...")
        
        // 打印所有传入的选项
        if let options = options {
            NSLog("📋 Options: \(options)")
            logger.debug("Options: \(options)")
        } else {
            NSLog("📋 No options provided")
            logger.debug("No options provided")
        }
        
        // 获取配置
        NSLog("📦 Getting protocol configuration...")
        guard let protocolConfiguration = self.protocolConfiguration as? NETunnelProviderProtocol else {
            NSLog("❌ Failed to get protocol configuration")
            logger.error("❌ Failed to get protocol configuration")
            let error = NSError(domain: "WireGuard", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid protocol configuration"
            ])
            completionHandler(error)
            return
        }
        NSLog("✅ Got protocol configuration")
        
        guard let providerConfiguration = protocolConfiguration.providerConfiguration else {
            logger.error("❌ Provider configuration is nil")
            let error = NSError(domain: "WireGuard", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Provider configuration not found"
            ])
            completionHandler(error)
            return
        }
        
        guard let configString = providerConfiguration["wg_config"] as? String else {
            NSLog("❌ WireGuard config string not found in provider configuration")
            NSLog("📋 Provider configuration keys: \(providerConfiguration.keys)")
            logger.error("❌ WireGuard config string not found in provider configuration")
            logger.debug("Provider configuration keys: \(providerConfiguration.keys)")
            let error = NSError(domain: "WireGuard", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "WireGuard configuration not found"
            ])
            completionHandler(error)
            return
        }
        
        NSLog("✅ Got WireGuard config, length: \(configString.count) bytes")
        NSLog("📄 Config content:\n\(configString)")
        logger.info("✅ Got WireGuard config, length: \(configString.count) bytes")
        logger.debug("Config preview: \(configString.prefix(100))...")
        
        // 检查是否启用 MorphProtocol
        if let useMorph = providerConfiguration["useMorphProtocol"] as? Bool, useMorph {
            NSLog("🔐 MorphProtocol 已启用")
            logger.info("🔐 MorphProtocol enabled")
            
            let encryptionKey = providerConfiguration["morphEncryptionKey"] as? String ?? ""
            let serverHost = providerConfiguration["morphServerHost"] as? String ?? ""
            let serverPort = providerConfiguration["morphServerPort"] as? Int ?? 0
            let layerCount = providerConfiguration["morphLayerCount"] as? Int ?? 3
            let paddingLength = providerConfiguration["morphPaddingLength"] as? Int ?? 8
            
            NSLog("🔐 MorphProtocol 配置:")
            NSLog("   服务器: \(serverHost):\(serverPort)")
            NSLog("   混淆层数: \(layerCount)")
            NSLog("   填充长度: \(paddingLength)")
            NSLog("   密钥长度: \(encryptionKey.count) 字符")
            
            logger.info("MorphProtocol 服务器: \(serverHost):\(serverPort)")
            logger.debug("混淆层数: \(layerCount), 填充长度: \(paddingLength)")
            
            do {
                morphClient = try MorphUDPClient(
                    encryptionKey: encryptionKey,
                    obfuscationLayer: layerCount,
                    paddingLength: paddingLength
                )
                
                morphClient?.onStateChange = { [weak self] state in
                    let stateStr = String(describing: state)
                    NSLog("🔐 MorphProtocol 状态: \(stateStr)")
                    self?.logger.info("MorphProtocol 状态: \(stateStr)")
                }
                
                morphClient?.onError = { [weak self] error in
                    NSLog("❌ MorphProtocol 错误: \(error.localizedDescription)")
                    self?.logger.error("MorphProtocol 错误: \(error.localizedDescription)")
                }
                
                morphClient?.onReceive = { [weak self] data in
                    NSLog("📥 MorphProtocol 接收数据: \(data.count) 字节")
                    self?.logger.debug("MorphProtocol 接收: \(data.count) 字节")
                }
                
                morphClient?.connect(host: serverHost, port: UInt16(serverPort))
                NSLog("✅ MorphProtocol 启动成功")
                logger.info("✅ MorphProtocol 启动成功")
            } catch {
                NSLog("❌ 初始化 MorphProtocol 失败: \(error.localizedDescription)")
                logger.error("❌ 初始化 MorphProtocol 失败: \(error.localizedDescription)")
                // 继续使用标准 WireGuard，不中断连接
            }
        } else {
            NSLog("ℹ️ MorphProtocol 未启用，使用标准 WireGuard")
            logger.info("MorphProtocol 未启用")
        }
        
        // 解析配置
        NSLog("🔧 Parsing WireGuard configuration...")
        let tunnelConfiguration: TunnelConfiguration
        do {
            tunnelConfiguration = try TunnelConfiguration(fromWgQuickConfig: configString)
            NSLog("✅ Successfully parsed WireGuard configuration")
            NSLog("📍 Interface addresses: \(tunnelConfiguration.interface.addresses.map { $0.stringRepresentation }.joined(separator: ", "))")
            NSLog("👥 Peers count: \(tunnelConfiguration.peers.count)")
            logger.info("✅ Successfully parsed WireGuard configuration")
            logger.debug("Interface: \(tunnelConfiguration.interface.addresses.map { $0.stringRepresentation }.joined(separator: ", "))")
            logger.debug("Peers: \(tunnelConfiguration.peers.count)")
        } catch {
            NSLog("❌ Failed to parse WireGuard config: \(error.localizedDescription)")
            NSLog("❌ Error details: \(error)")
            logger.error("❌ Failed to parse WireGuard config: \(error.localizedDescription)")
            let nsError = NSError(domain: "WireGuard", code: 4, userInfo: [
                NSLocalizedDescriptionKey: "Invalid WireGuard configuration: \(error.localizedDescription)"
            ])
            completionHandler(nsError)
            return
        }
        
        // 创建适配器
        NSLog("🔨 Creating WireGuard adapter...")
        logger.info("Creating WireGuard adapter...")
        adapter = WireGuardAdapter(with: self) { [weak self] logLevel, message in
            NSLog("WireGuard[\(logLevel)]: \(message)")
            self?.logger.log(level: self?.osLogLevel(from: logLevel) ?? .default, "WireGuard: \(message)")
        }
        NSLog("✅ WireGuard adapter created")
        
        // 启动隧道
        NSLog("🚀 Starting WireGuard adapter...")
        logger.info("Starting WireGuard adapter...")
        adapter?.start(tunnelConfiguration: tunnelConfiguration) { [weak self] error in
            if let error = error {
                NSLog("❌ Failed to start WireGuard: \(error.localizedDescription)")
                NSLog("❌ Error details: \(error)")
                self?.logger.error("❌ Failed to start WireGuard: \(error.localizedDescription)")
                completionHandler(error)
            } else {
                NSLog("✅ WireGuard tunnel started successfully!")
                self?.logger.info("✅ WireGuard tunnel started successfully!")
                completionHandler(nil)
            }
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, 
                           completionHandler: @escaping () -> Void) {
        NSLog("🛑 Stopping WireGuard tunnel, reason: \(reason.rawValue)")
        logger.info("🛑 Stopping WireGuard tunnel, reason: \(reason.rawValue)")
        
        // 停止 MorphProtocol（如果正在运行）
        if let morphClient = morphClient {
            NSLog("🛑 停止 MorphProtocol")
            logger.info("停止 MorphProtocol")
            morphClient.disconnect()
            self.morphClient = nil
        }
        
        adapter?.stop { [weak self] error in
            if let error = error {
                NSLog("❌ Error stopping WireGuard: \(error.localizedDescription)")
                self?.logger.error("❌ Error stopping WireGuard: \(error.localizedDescription)")
            } else {
                NSLog("✅ WireGuard tunnel stopped successfully")
                self?.logger.info("✅ WireGuard tunnel stopped successfully")
            }
            self?.adapter = nil
            completionHandler()
        }
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        logger.debug("📨 Received app message")
        completionHandler?(nil)
    }
    
    // 辅助方法：转换日志级别
    private func osLogLevel(from logLevel: WireGuardLogLevel) -> OSLogType {
        switch logLevel {
        case .verbose:
            return .debug
        case .error:
            return .error
        @unknown default:
            return .default
        }
    }
}
