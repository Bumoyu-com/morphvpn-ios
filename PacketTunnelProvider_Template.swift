import NetworkExtension
import os.log

/// WireGuard Packet Tunnel Provider
/// 这是一个简化的实现，用于测试 VPN 配置创建
/// 要实现真正的 WireGuard 协议，需要集成 WireGuardKit
class PacketTunnelProvider: NEPacketTunnelProvider {
    
    private let log = OSLog(subsystem: "com.morphvpn.app.WireGuardExtension", category: "PacketTunnel")
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        os_log("🟢 WireGuard Extension: Starting tunnel", log: log, type: .info)
        
        // 获取 VPN 配置
        guard let protocolConfiguration = self.protocolConfiguration as? NETunnelProviderProtocol else {
            os_log("❌ WireGuard Extension: Invalid protocol configuration", log: log, type: .error)
            completionHandler(NSError(domain: "WireGuard", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid protocol configuration"
            ]))
            return
        }
        
        // 获取 WireGuard 配置
        guard let providerConfiguration = protocolConfiguration.providerConfiguration,
              let wgConfig = providerConfiguration["wg_config"] as? String else {
            os_log("❌ WireGuard Extension: Missing WireGuard configuration", log: log, type: .error)
            completionHandler(NSError(domain: "WireGuard", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Missing WireGuard configuration"
            ]))
            return
        }
        
        os_log("📝 WireGuard Extension: Config received (length: %d)", log: log, type: .info, wgConfig.count)
        
        // 解析 WireGuard 配置
        let configLines = wgConfig.components(separatedBy: .newlines)
        var interfaceAddress: String?
        var endpoint: String?
        
        for line in configLines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("Address") {
                interfaceAddress = trimmed.components(separatedBy: "=").last?.trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("Endpoint") {
                endpoint = trimmed.components(separatedBy: "=").last?.trimmingCharacters(in: .whitespaces)
            }
        }
        
        os_log("🔍 WireGuard Extension: Interface Address: %{public}@", log: log, type: .info, interfaceAddress ?? "none")
        os_log("🔍 WireGuard Extension: Endpoint: %{public}@", log: log, type: .info, endpoint ?? "none")
        
        // 配置网络设置
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: endpoint?.components(separatedBy: ":").first ?? "0.0.0.0")
        
        // 配置 IPv4
        if let address = interfaceAddress?.components(separatedBy: "/").first {
            let ipv4Settings = NEIPv4Settings(addresses: [address], subnetMasks: ["255.255.255.0"])
            ipv4Settings.includedRoutes = [NEIPv4Route.default()]
            networkSettings.ipv4Settings = ipv4Settings
        }
        
        // 配置 DNS
        let dnsSettings = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8"])
        networkSettings.dnsSettings = dnsSettings
        
        // 应用网络设置
        setTunnelNetworkSettings(networkSettings) { [weak self] error in
            if let error = error {
                os_log("❌ WireGuard Extension: Failed to set network settings: %{public}@", log: self?.log ?? OSLog.default, type: .error, error.localizedDescription)
                completionHandler(error)
                return
            }
            
            os_log("✅ WireGuard Extension: Network settings applied", log: self?.log ?? OSLog.default, type: .info)
            
            // TODO: 这里应该启动 WireGuard 隧道
            // 目前只是标记为已连接，不会实际传输数据
            os_log("⚠️ WireGuard Extension: Tunnel marked as connected (no actual WireGuard implementation)", log: self?.log ?? OSLog.default, type: .info)
            
            completionHandler(nil)
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        os_log("🔴 WireGuard Extension: Stopping tunnel, reason: %{public}@", log: log, type: .info, String(describing: reason))
        
        // TODO: 清理 WireGuard 资源
        
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        os_log("📨 WireGuard Extension: Received app message", log: log, type: .info)
        
        // 可以用于主 App 和 Extension 之间的通信
        // 例如：获取统计信息、更新配置等
        
        completionHandler?(nil)
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        os_log("😴 WireGuard Extension: Sleep", log: log, type: .info)
        completionHandler()
    }
    
    override func wake() {
        os_log("👁️ WireGuard Extension: Wake", log: log, type: .info)
    }
}

// MARK: - Helper Extensions

extension NEProviderStopReason: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none:
            return "none"
        case .userInitiated:
            return "userInitiated"
        case .providerFailed:
            return "providerFailed"
        case .noNetworkAvailable:
            return "noNetworkAvailable"
        case .unrecoverableNetworkChange:
            return "unrecoverableNetworkChange"
        case .providerDisabled:
            return "providerDisabled"
        case .authenticationCanceled:
            return "authenticationCanceled"
        case .configurationFailed:
            return "configurationFailed"
        case .idleTimeout:
            return "idleTimeout"
        case .configurationDisabled:
            return "configurationDisabled"
        case .configurationRemoved:
            return "configurationRemoved"
        case .superceded:
            return "superceded"
        case .userLogout:
            return "userLogout"
        case .userSwitch:
            return "userSwitch"
        case .connectionFailed:
            return "connectionFailed"
        case .sleep:
            return "sleep"
        case .appUpdate:
            return "appUpdate"
        @unknown default:
            return "unknown(\(rawValue))"
        }
    }
}
