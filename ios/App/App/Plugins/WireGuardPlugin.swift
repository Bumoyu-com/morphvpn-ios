import Foundation
import Capacitor
import NetworkExtension

/**
 * WireGuard Capacitor Plugin for iOS
 * 使用NetworkExtension框架实现WireGuard VPN功能
 */
@objc(WireGuardPlugin)
public class WireGuardPlugin: CAPPlugin {
    
    private var vpnManager: NETunnelProviderManager?
    private var statusObserver: NSObjectProtocol?
    
    override public func load() {
        // 加载VPN配置
        loadVPNManager()
        
        // 监听VPN状态变化
        setupStatusObserver()
    }
    
    deinit {
        if let observer = statusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Plugin Methods
    
    /**
     * 连接WireGuard VPN
     */
    @objc func connect(_ call: CAPPluginCall) {
        guard let config = call.getString("config"),
              let tunnelName = call.getString("tunnelName") else {
            call.reject("Missing required parameters: config and tunnelName")
            return
        }
        
        // 保存配置并连接
        saveAndConnect(config: config, tunnelName: tunnelName) { success, error in
            if success {
                call.resolve(["success": true])
            } else {
                call.reject(error ?? "Failed to connect")
            }
        }
    }
    
    /**
     * 断开WireGuard VPN连接
     */
    @objc func disconnect(_ call: CAPPluginCall) {
        guard let manager = vpnManager else {
            call.reject("VPN manager not initialized")
            return
        }
        
        manager.connection.stopVPNTunnel()
        call.resolve(["success": true])
    }
    
    /**
     * 获取当前连接状态
     */
    @objc func getStatus(_ call: CAPPluginCall) {
        guard let manager = vpnManager else {
            call.resolve([
                "status": "disconnected"
            ])
            return
        }
        
        let status = getConnectionStatus(manager.connection.status)
        var result: [String: Any] = ["status": status]
        
        // 尝试获取统计信息（需要Network Extension支持）
        if let session = manager.connection as? NETunnelProviderSession {
            // 注意：实际的流量统计需要在Network Extension中实现
            result["bytesUploaded"] = 0
            result["bytesDownloaded"] = 0
        }
        
        call.resolve(result)
    }
    
    /**
     * 保存WireGuard配置
     */
    @objc func saveConfig(_ call: CAPPluginCall) {
        guard let config = call.getString("config"),
              let tunnelName = call.getString("tunnelName") else {
            call.reject("Missing required parameters: config and tunnelName")
            return
        }
        
        saveConfiguration(config: config, tunnelName: tunnelName) { success, error in
            if success {
                call.resolve(["success": true])
            } else {
                call.reject(error ?? "Failed to save config")
            }
        }
    }
    
    /**
     * 删除WireGuard配置
     */
    @objc func deleteConfig(_ call: CAPPluginCall) {
        guard let tunnelName = call.getString("tunnelName") else {
            call.reject("Missing required parameter: tunnelName")
            return
        }
        
        deleteConfiguration(tunnelName: tunnelName) { success, error in
            if success {
                call.resolve(["success": true])
            } else {
                call.reject(error ?? "Failed to delete config")
            }
        }
    }
    
    /**
     * 获取所有已保存的隧道名称
     */
    @objc func listTunnels(_ call: CAPPluginCall) {
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            if let error = error {
                call.reject("Failed to load tunnels: \(error.localizedDescription)")
                return
            }
            
            let tunnelNames = managers?.compactMap { $0.localizedDescription } ?? []
            call.resolve(["tunnels": tunnelNames])
        }
    }
    
    // MARK: - Private Methods
    
    private func loadVPNManager() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            if let error = error {
                print("Failed to load VPN managers: \(error.localizedDescription)")
                return
            }
            
            self?.vpnManager = managers?.first
        }
    }
    
    private func setupStatusObserver() {
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let connection = notification.object as? NEVPNConnection else { return }
            let status = self?.getConnectionStatus(connection.status) ?? "unknown"
            
            // 通知JavaScript层状态变化
            self?.notifyListeners("statusChanged", data: ["status": status])
        }
    }
    
    private func getConnectionStatus(_ status: NEVPNStatus) -> String {
        switch status {
        case .invalid:
            return "invalid"
        case .disconnected:
            return "disconnected"
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        case .reasserting:
            return "reconnecting"
        case .disconnecting:
            return "disconnecting"
        @unknown default:
            return "unknown"
        }
    }
    
    private func saveAndConnect(config: String, tunnelName: String, completion: @escaping (Bool, String?) -> Void) {
        // 首先保存配置
        saveConfiguration(config: config, tunnelName: tunnelName) { [weak self] success, error in
            guard success else {
                completion(false, error)
                return
            }
            
            // 然后连接
            self?.startVPN(completion: completion)
        }
    }
    
    private func saveConfiguration(config: String, tunnelName: String, completion: @escaping (Bool, String?) -> Void) {
        // 创建VPN配置
        let providerProtocol = NETunnelProviderProtocol()
        
        // 注意：这里需要替换为你的Network Extension的Bundle ID
        providerProtocol.providerBundleIdentifier = "com.example.app.WireGuardExtension"
        providerProtocol.serverAddress = "WireGuard"
        
        // 将WireGuard配置保存到providerConfiguration
        providerProtocol.providerConfiguration = [
            "wg_config": config
        ]
        
        // 加载或创建VPN Manager
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            let manager: NETunnelProviderManager
            
            if let existingManager = managers?.first {
                manager = existingManager
            } else {
                manager = NETunnelProviderManager()
            }
            
            manager.localizedDescription = tunnelName
            manager.protocolConfiguration = providerProtocol
            manager.isEnabled = true
            
            // 保存配置
            manager.saveToPreferences { error in
                if let error = error {
                    completion(false, "Failed to save VPN configuration: \(error.localizedDescription)")
                    return
                }
                
                // 重新加载以确保配置生效
                manager.loadFromPreferences { error in
                    if let error = error {
                        completion(false, "Failed to reload VPN configuration: \(error.localizedDescription)")
                        return
                    }
                    
                    self?.vpnManager = manager
                    completion(true, nil)
                }
            }
        }
    }
    
    private func startVPN(completion: @escaping (Bool, String?) -> Void) {
        guard let manager = vpnManager else {
            completion(false, "VPN manager not initialized")
            return
        }
        
        do {
            try manager.connection.startVPNTunnel()
            completion(true, nil)
        } catch {
            completion(false, "Failed to start VPN: \(error.localizedDescription)")
        }
    }
    
    private func deleteConfiguration(tunnelName: String, completion: @escaping (Bool, String?) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            if let error = error {
                completion(false, "Failed to load configurations: \(error.localizedDescription)")
                return
            }
            
            guard let manager = managers?.first(where: { $0.localizedDescription == tunnelName }) else {
                completion(false, "Configuration not found")
                return
            }
            
            manager.removeFromPreferences { error in
                if let error = error {
                    completion(false, "Failed to delete configuration: \(error.localizedDescription)")
                    return
                }
                
                completion(true, nil)
            }
        }
    }
}
