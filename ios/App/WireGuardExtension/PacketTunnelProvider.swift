import NetworkExtension
import WireGuardKit
import os.log

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    private var adapter: WireGuardAdapter?
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
