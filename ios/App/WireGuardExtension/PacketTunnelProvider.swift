import NetworkExtension
import WireGuardKit
import os.log

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    private var adapter: WireGuardAdapter?
    private lazy var logger = Logger(subsystem: "com.morphvpn.app.WireGuardExtension", category: "PacketTunnel")
    
    override init() {
        super.init()
        NSLog("🎯 PacketTunnelProvider: init() called")
        logger.info("🎯 PacketTunnelProvider: Initialized")
    }
    
    override func startTunnel(options: [String : NSObject]?, 
                            completionHandler: @escaping (Error?) -> Void) {
        
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
        logger.info("✅ Got WireGuard config, length: \(configString.count) bytes")
        
        // 解析 WireGuard 配置
        NSLog("🔧 Parsing WireGuard configuration...")
        logger.info("🔧 Parsing WireGuard configuration...")
        
        guard let tunnelConfiguration = try? TunnelConfiguration(fromWgQuickConfig: configString) else {
            NSLog("❌ Failed to parse WireGuard configuration")
            logger.error("❌ Failed to parse WireGuard configuration")
            let error = NSError(domain: "WireGuard", code: 4, userInfo: [
                NSLocalizedDescriptionKey: "Invalid WireGuard configuration format"
            ])
            completionHandler(error)
            return
        }
        
        NSLog("✅ Successfully parsed WireGuard configuration")
        logger.info("✅ Successfully parsed WireGuard configuration")
        
        // 启动 WireGuard adapter
        NSLog("🚀 Starting WireGuard adapter...")
        logger.info("🚀 Starting WireGuard adapter...")
        
        adapter = WireGuardAdapter(with: self) { logLevel, message in
            NSLog("WireGuard: [\(logLevel)] \(message)")
        }
        
        adapter?.start(tunnelConfiguration: tunnelConfiguration) { [weak self] error in
            if let error = error {
                NSLog("❌ WireGuard adapter failed to start: \(error)")
                self?.logger.error("❌ WireGuard adapter failed to start: \(error.localizedDescription)")
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
        NSLog("🛑 PacketTunnelProvider: stopTunnel() called, reason: \(reason)")
        logger.info("🛑 Stopping WireGuard tunnel, reason: \(reason.rawValue)")
        
        adapter?.stop { error in
            if let error = error {
                NSLog("❌ Error stopping adapter: \(error)")
            } else {
                NSLog("✅ WireGuard tunnel stopped")
            }
            completionHandler()
        }
        
        adapter = nil
    }
    
    override func handleAppMessage(_ messageData: Data, 
                                  completionHandler: ((Data?) -> Void)?) {
        NSLog("📨 PacketTunnelProvider: handleAppMessage() called")
        logger.debug("📨 Received app message")
        
        completionHandler?(nil)
    }
}
