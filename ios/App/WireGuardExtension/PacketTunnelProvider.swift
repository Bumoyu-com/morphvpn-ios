import NetworkExtension
import WireGuardKit
import os.log

/// WireGuard Packet Tunnel Provider with WireGuardKit
/// 完整的 WireGuard VPN 实现
class PacketTunnelProvider: NEPacketTunnelProvider {
    
    private let log = OSLog(subsystem: "com.morphvpn.app.WireGuardExtension", category: "PacketTunnel")
    private var adapter: WireGuardAdapter?
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        os_log("🟢 WireGuard: Starting tunnel", log: log, type: .info)
        
        // 获取 VPN 配置
        guard let protocolConfiguration = self.protocolConfiguration as? NETunnelProviderProtocol else {
            os_log("❌ WireGuard: Invalid protocol configuration", log: log, type: .error)
            completionHandler(WireGuardError.invalidConfiguration)
            return
        }
        
        // 获取 WireGuard 配置字符串
        guard let providerConfiguration = protocolConfiguration.providerConfiguration,
              let wgConfigString = providerConfiguration["wg_config"] as? String else {
            os_log("❌ WireGuard: Missing WireGuard configuration", log: log, type: .error)
            completionHandler(WireGuardError.missingConfiguration)
            return
        }
        
        os_log("📝 WireGuard: Parsing configuration (length: %d)", log: log, type: .info, wgConfigString.count)
        
        // 解析 WireGuard 配置
        guard let tunnelConfiguration = try? TunnelConfiguration(fromWgQuickConfig: wgConfigString) else {
            os_log("❌ WireGuard: Failed to parse configuration", log: log, type: .error)
            completionHandler(WireGuardError.invalidWireGuardConfig)
            return
        }
        
        os_log("✅ WireGuard: Configuration parsed successfully", log: log, type: .info)
        os_log("   Interface: %{public}@", log: log, type: .info, tunnelConfiguration.interface.addresses.map { $0.stringRepresentation }.joined(separator: ", "))
        os_log("   Peers: %d", log: log, type: .info, tunnelConfiguration.peers.count)
        
        // 创建 WireGuard Adapter
        adapter = WireGuardAdapter(with: self) { logLevel, message in
            os_log("WireGuard: [%{public}@] %{public}@", log: self.log, type: .debug, logLevel.description, message)
        }
        
        // 启动 WireGuard 隧道
        adapter?.start(tunnelConfiguration: tunnelConfiguration) { [weak self] error in
            if let error = error {
                os_log("❌ WireGuard: Failed to start tunnel: %{public}@", log: self?.log ?? OSLog.default, type: .error, error.localizedDescription)
                completionHandler(error)
                return
            }
            
            os_log("✅ WireGuard: Tunnel started successfully", log: self?.log ?? OSLog.default, type: .info)
            completionHandler(nil)
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        os_log("🔴 WireGuard: Stopping tunnel, reason: %{public}@", log: log, type: .info, reason.description)
        
        adapter?.stop { [weak self] error in
            if let error = error {
                os_log("⚠️ WireGuard: Error stopping tunnel: %{public}@", log: self?.log ?? OSLog.default, type: .error, error.localizedDescription)
            } else {
                os_log("✅ WireGuard: Tunnel stopped successfully", log: self?.log ?? OSLog.default, type: .info)
            }
            
            self?.adapter = nil
            completionHandler()
        }
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        os_log("📨 WireGuard: Received app message", log: log, type: .info)
        
        // 可以用于获取统计信息等
        guard let adapter = adapter else {
            completionHandler?(nil)
            return
        }
        
        // 获取运行时配置（包含统计信息）
        adapter.getRuntimeConfiguration { settings in
            guard let settings = settings else {
                completionHandler?(nil)
                return
            }
            
            // 构建统计信息
            var stats: [String: Any] = [:]
            
            if let interface = settings.split(separator: "\n").first(where: { $0.hasPrefix("interface:") }) {
                stats["interface"] = String(interface)
            }
            
            // 提取传输字节数
            let lines = settings.split(separator: "\n")
            for (index, line) in lines.enumerated() {
                if line.hasPrefix("peer:") {
                    // 查找下一行的 rx_bytes 和 tx_bytes
                    if index + 1 < lines.count {
                        let nextLine = lines[index + 1]
                        if nextLine.contains("rx_bytes") {
                            let components = nextLine.split(separator: "=")
                            if components.count >= 2 {
                                stats["rx_bytes"] = String(components[1].trimmingCharacters(in: .whitespaces))
                            }
                        }
                    }
                    if index + 2 < lines.count {
                        let nextLine = lines[index + 2]
                        if nextLine.contains("tx_bytes") {
                            let components = nextLine.split(separator: "=")
                            if components.count >= 2 {
                                stats["tx_bytes"] = String(components[1].trimmingCharacters(in: .whitespaces))
                            }
                        }
                    }
                }
            }
            
            // 转换为 JSON
            if let jsonData = try? JSONSerialization.data(withJSONObject: stats, options: []) {
                completionHandler?(jsonData)
            } else {
                completionHandler?(nil)
            }
        }
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        os_log("😴 WireGuard: Sleep", log: log, type: .info)
        completionHandler()
    }
    
    override func wake() {
        os_log("👁️ WireGuard: Wake", log: log, type: .info)
    }
}

// MARK: - Errors

enum WireGuardError: LocalizedError {
    case invalidConfiguration
    case missingConfiguration
    case invalidWireGuardConfig
    
    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Invalid VPN protocol configuration"
        case .missingConfiguration:
            return "Missing WireGuard configuration"
        case .invalidWireGuardConfig:
            return "Invalid WireGuard configuration format"
        }
    }
}

// MARK: - Helper Extensions

extension NEProviderStopReason: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none: return "none"
        case .userInitiated: return "userInitiated"
        case .providerFailed: return "providerFailed"
        case .noNetworkAvailable: return "noNetworkAvailable"
        case .unrecoverableNetworkChange: return "unrecoverableNetworkChange"
        case .providerDisabled: return "providerDisabled"
        case .authenticationCanceled: return "authenticationCanceled"
        case .configurationFailed: return "configurationFailed"
        case .idleTimeout: return "idleTimeout"
        case .configurationDisabled: return "configurationDisabled"
        case .configurationRemoved: return "configurationRemoved"
        case .superceded: return "superceded"
        case .userLogout: return "userLogout"
        case .userSwitch: return "userSwitch"
        case .connectionFailed: return "connectionFailed"
        case .sleep: return "sleep"
        case .appUpdate: return "appUpdate"
        @unknown default: return "unknown(\(rawValue))"
        }
    }
}

extension WireGuardLogLevel {
    var description: String {
        switch self {
        case .verbose: return "VERBOSE"
        case .error: return "ERROR"
        @unknown default: return "UNKNOWN"
        }
    }
}
