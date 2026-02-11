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
        
        // 检查是否有 MorphProtocol 配置
        var finalConfigString = configString
        if let morphConfigJSON = providerConfiguration["morph_config"] as? String {
            NSLog("🎭 MorphProtocol config found, starting local proxy in extension...")
            finalConfigString = startMorphProxy(wgConfig: configString, morphConfigJSON: morphConfigJSON)
        }
        
        // 解析 WireGuard 配置
        guard let tunnelConfiguration = try? TunnelConfiguration(fromWgQuickConfig: finalConfigString) else {
            NSLog("❌ Failed to parse WireGuard configuration")
            let error = NSError(domain: "WireGuard", code: 4, userInfo: [
                NSLocalizedDescriptionKey: "Invalid WireGuard configuration format"
            ])
            completionHandler(error)
            return
        }
        
        NSLog("✅ Parsed WireGuard config")
        
        // 启动 WireGuard adapter
        adapter = WireGuardAdapter(with: self) { logLevel, message in
            NSLog("WireGuard: [\(logLevel)] \(message)")
        }
        
        adapter?.start(tunnelConfiguration: tunnelConfiguration) { [weak self] error in
            if let error = error {
                NSLog("❌ WireGuard adapter failed to start: \(error)")
                completionHandler(error)
            } else {
                NSLog("✅ WireGuard tunnel started!")
                completionHandler(nil)
            }
        }
    }
    
    // MARK: - MorphProtocol 本地代理（运行在 Extension 进程内）
    
    private var morphProxy: MorphExtensionProxy?
    
    /// 在 Extension 进程中启动 MorphProtocol 本地 UDP 代理
    /// 返回修改后的 WireGuard 配置（Endpoint 指向本地代理端口）
    private func startMorphProxy(wgConfig: String, morphConfigJSON: String) -> String {
        guard let jsonData = morphConfigJSON.data(using: .utf8),
              let config = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            NSLog("❌ Failed to parse morph_config JSON")
            return wgConfig
        }
        
        guard let host = config["host"] as? String,
              let sessionPort = config["sessionPort"] as? Int,
              let key = config["key"] as? Int,
              let layer = config["layer"] as? Int,
              let padding = config["padding"] as? Int else {
            NSLog("❌ Missing required morph_config fields")
            return wgConfig
        }
        
        let templateId = config["templateId"] as? Int ?? 1
        let clientIDBase64 = config["clientID"] as? String ?? ""
        let clientID = Data(base64Encoded: clientIDBase64) ?? Data(count: 16)
        let fnInitor = config["fnInitor"] as? [String: Any]
        
        do {
            let proxy = try MorphExtensionProxy(
                host: host,
                sessionPort: UInt16(sessionPort),
                key: key,
                layer: layer,
                padding: padding,
                templateId: templateId,
                clientID: clientID,
                fnInitor: fnInitor
            )
            
            guard let localPort = proxy.start() else {
                NSLog("❌ Failed to start MorphProtocol proxy")
                return wgConfig
            }
            
            self.morphProxy = proxy
            NSLog("✅ MorphProtocol proxy started on 127.0.0.1:\(localPort)")
            
            // 修改 WireGuard 配置的 Endpoint 为本地代理端口
            return replaceEndpoint(in: wgConfig, newEndpoint: "127.0.0.1:\(localPort)")
        } catch {
            NSLog("❌ MorphProtocol proxy init error: \(error)")
            return wgConfig
        }
    }
    
    private func replaceEndpoint(in config: String, newEndpoint: String) -> String {
        var lines = config.components(separatedBy: "\n")
        for i in 0..<lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("Endpoint") && trimmed.contains("=") {
                lines[i] = "Endpoint = \(newEndpoint)"
                NSLog("🔧 Replaced Endpoint → \(newEndpoint)")
                break
            }
        }
        return lines.joined(separator: "\n")
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, 
                           completionHandler: @escaping () -> Void) {
        NSLog("🛑 PacketTunnelProvider: stopTunnel() called, reason: \(reason)")
        logger.info("🛑 Stopping WireGuard tunnel, reason: \(reason.rawValue)")
        
        morphProxy?.stop()
        morphProxy = nil
        
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
