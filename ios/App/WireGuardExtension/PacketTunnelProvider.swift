import NetworkExtension
import WireGuardKit
import os.log

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    private var adapter: WireGuardAdapter?
    private lazy var logger = Logger(subsystem: "com.morphvpn.app.WireGuardExtension", category: "PacketTunnel")
    
    override func startTunnel(options: [String : NSObject]?, 
                            completionHandler: @escaping (Error?) -> Void) {
        
        logger.info("🚀 Starting WireGuard tunnel...")
        
        // 获取配置
        guard let protocolConfiguration = self.protocolConfiguration as? NETunnelProviderProtocol else {
            logger.error("❌ Failed to get protocol configuration")
            let error = NSError(domain: "WireGuard", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid protocol configuration"
            ])
            completionHandler(error)
            return
        }
        
        guard let providerConfiguration = protocolConfiguration.providerConfiguration else {
            logger.error("❌ Provider configuration is nil")
            let error = NSError(domain: "WireGuard", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Provider configuration not found"
            ])
            completionHandler(error)
            return
        }
        
        guard let configString = providerConfiguration["wg_config"] as? String else {
            logger.error("❌ WireGuard config string not found in provider configuration")
            logger.debug("Provider configuration keys: \(providerConfiguration.keys)")
            let error = NSError(domain: "WireGuard", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "WireGuard configuration not found"
            ])
            completionHandler(error)
            return
        }
        
        logger.info("✅ Got WireGuard config, length: \(configString.count) bytes")
        logger.debug("Config preview: \(configString.prefix(100))...")
        
        // 解析配置
        let tunnelConfiguration: TunnelConfiguration
        do {
            tunnelConfiguration = try TunnelConfiguration(fromWgQuickConfig: configString)
            logger.info("✅ Successfully parsed WireGuard configuration")
            logger.debug("Interface: \(tunnelConfiguration.interface.addresses.map { $0.stringRepresentation }.joined(separator: ", "))")
            logger.debug("Peers: \(tunnelConfiguration.peers.count)")
        } catch {
            logger.error("❌ Failed to parse WireGuard config: \(error.localizedDescription)")
            let nsError = NSError(domain: "WireGuard", code: 4, userInfo: [
                NSLocalizedDescriptionKey: "Invalid WireGuard configuration: \(error.localizedDescription)"
            ])
            completionHandler(nsError)
            return
        }
        
        // 创建适配器
        logger.info("Creating WireGuard adapter...")
        adapter = WireGuardAdapter(with: self) { [weak self] logLevel, message in
            self?.logger.log(level: self?.osLogLevel(from: logLevel) ?? .default, "WireGuard: \(message)")
        }
        
        // 启动隧道
        logger.info("Starting WireGuard adapter...")
        adapter?.start(tunnelConfiguration: tunnelConfiguration) { [weak self] error in
            if let error = error {
                self?.logger.error("❌ Failed to start WireGuard: \(error.localizedDescription)")
                completionHandler(error)
            } else {
                self?.logger.info("✅ WireGuard tunnel started successfully!")
                completionHandler(nil)
            }
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, 
                           completionHandler: @escaping () -> Void) {
        logger.info("🛑 Stopping WireGuard tunnel, reason: \(reason.rawValue)")
        
        adapter?.stop { [weak self] error in
            if let error = error {
                self?.logger.error("❌ Error stopping WireGuard: \(error.localizedDescription)")
            } else {
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
