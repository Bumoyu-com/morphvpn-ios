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
    /// 取消标志：disconnect() 调用后置 true，connect 流程各回调检查此标志提前退出
    private var disconnectRequested: Bool = false
    
    override public func load() {
        print("✅ WireGuardPlugin: Plugin loaded successfully")
        
        // 加载VPN配置
        loadVPNManager()
        
        // 监听VPN状态变化（只注册一次）
        setupStatusObserver()
        
        print("✅ WireGuardPlugin: Initialization complete")
    }
    
    deinit {
        if let observer = statusObserver {
            NotificationCenter.default.removeObserver(observer)
            statusObserver = nil
        }
    }
    
    // MARK: - Plugin Methods
    
    /**
     * 连接WireGuard VPN
     * 支持可选的 morphConfig 参数，传递给 Network Extension 进程
     */
    @objc func connect(_ call: CAPPluginCall) {
        print("🔵 WireGuardPlugin: connect() called")
        
        // 每次新的 connect 调用重置取消标志
        disconnectRequested = false
        
        guard let config = call.getString("config"),
              let tunnelName = call.getString("tunnelName") else {
            print("❌ WireGuardPlugin: Missing parameters")
            call.reject("Missing required parameters: config and tunnelName")
            return
        }
        
        // 可选：MorphProtocol 配置（JSON 字符串）
        let morphConfig = call.getString("morphConfig")
        if morphConfig != nil {
            print("🔵 WireGuardPlugin: MorphProtocol config provided, will run in Extension")
        }
        
        print("🔵 WireGuardPlugin: Tunnel name: \(tunnelName)")
        print("🔵 WireGuardPlugin: Config length: \(config.count) bytes")
        
        // 保存配置并连接
        saveAndConnect(config: config, tunnelName: tunnelName, morphConfig: morphConfig) { [weak self] success, error in
            // 如果在异步等待期间 disconnect() 被调用，丢弃结果
            if self?.disconnectRequested == true {
                print("⚠️ WireGuardPlugin: connect() aborted by disconnect()")
                call.reject("Cancelled")
                return
            }
            if success {
                print("✅ WireGuardPlugin: Connection successful")
                call.resolve(["success": true])
            } else {
                print("❌ WireGuardPlugin: Connection failed - \(error ?? "unknown error")")
                call.reject(error ?? "Failed to connect")
            }
        }
    }
    
    /**
     * 断开WireGuard VPN连接
     * 可在任意时点调用：vpnManager 为 nil（连接尚未建立或已清理）时直接 resolve，不报错。
     * 同时设置 disconnectRequested 标志，打断正在进行的 connect 异步流程。
     */
    @objc func disconnect(_ call: CAPPluginCall) {
        print("🔵 WireGuardPlugin: disconnect() called")
        
        // 设置取消标志，打断 connect 流程中的异步回调链
        disconnectRequested = true
        
        guard let manager = vpnManager else {
            // vpnManager 尚未初始化（connect 还在异步配置阶段，或本就未连接）
            print("⚠️ WireGuardPlugin: disconnect() called but vpnManager is nil, resolving as no-op")
            call.resolve(["success": true])
            return
        }
        
        manager.connection.stopVPNTunnel()
        print("✅ WireGuardPlugin: stopVPNTunnel() called")
        call.resolve(["success": true])
    }
    
    /**
     * 获取当前连接状态
     */
    @objc func getStatus(_ call: CAPPluginCall) {
        print("🔵 WireGuardPlugin: getStatus() called")
        
        guard let manager = vpnManager else {
            print("⚠️ WireGuardPlugin: VPN manager is nil, returning disconnected")
            call.resolve([
                "status": "disconnected"
            ])
            return
        }
        
        let status = getConnectionStatus(manager.connection.status)
        var result: [String: Any] = ["status": status]
        
        print("🔵 WireGuardPlugin: Current status - \(status)")
        
        // 尝试获取统计信息（需要Network Extension支持）
        if let session = manager.connection as? NETunnelProviderSession {
            // 注意：实际的流量统计需要在Network Extension中实现
            result["bytesUploaded"] = 0
            result["bytesDownloaded"] = 0
        }
        
        call.resolve(result)
    }

    /**
     * 读取 Extension 进程的共享日志
     */
    @objc func readExtensionLog(_ call: CAPPluginCall) {
        let fm = FileManager.default
        if let containerURL = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.com.morphvpn.app.wireguard") {
            let url = containerURL.appendingPathComponent("extension_log.txt")
            let log = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            call.resolve(["log": log])
        } else {
            call.resolve(["log": "App Group container not available"])
        }
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
        // 移除旧的 observer（防止重复注册）
        if let observer = statusObserver {
            NotificationCenter.default.removeObserver(observer)
            statusObserver = nil
        }
        
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // 只处理当前 vpnManager 的 connection 状态变化，忽略其他 manager
            guard let self = self,
                  let connection = notification.object as? NEVPNConnection,
                  let manager = self.vpnManager,
                  connection === manager.connection else { return }
            
            let status = self.getConnectionStatus(connection.status)
            
            print("📡 WireGuardPlugin: VPN status changed to: \(status)")
            
            if status == "disconnected" || status == "disconnecting" {
                print("🔍 WireGuardPlugin: Checking for connection errors...")
            }
            
            self.notifyListeners("statusChanged", data: ["status": status])
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
    
    private func saveAndConnect(config: String, tunnelName: String, morphConfig: String? = nil, completion: @escaping (Bool, String?) -> Void) {
        saveConfiguration(config: config, tunnelName: tunnelName, morphConfig: morphConfig) { [weak self] success, error in
            // saveConfiguration 完成后检查是否已被取消
            if self?.disconnectRequested == true {
                print("⚠️ WireGuardPlugin: saveAndConnect aborted after saveConfiguration")
                completion(false, "Cancelled")
                return
            }
            guard success else {
                completion(false, error)
                return
            }
            self?.startVPN(completion: completion)
        }
    }
    
    private func saveConfiguration(config: String, tunnelName: String, morphConfig: String? = nil, completion: @escaping (Bool, String?) -> Void) {
        print("🔵 WireGuardPlugin: saveConfiguration called")
        
        let providerProtocol = NETunnelProviderProtocol()
        providerProtocol.providerBundleIdentifier = "com.morphvpn.app.WireGuardExtension"
        providerProtocol.serverAddress = "WireGuard"
        
        // providerConfiguration 传递给 PacketTunnelProvider
        var providerConfiguration: [String: Any] = [
            "wg_config": config
        ]
        
        // 如果有 MorphProtocol 配置，一并传入 Extension
        if let morphConfig = morphConfig {
            providerConfiguration["morph_config"] = morphConfig
            print("🔵 WireGuardPlugin: morph_config added to providerConfiguration")
        }
        
        providerProtocol.providerConfiguration = providerConfiguration
        
        // 加载或创建VPN Manager
        // NETunnelProviderManager 的回调在主线程执行，与 disconnectRequested 的读写线程一致
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
            print("🔵 WireGuardPlugin: Saving VPN configuration to preferences...")
            manager.saveToPreferences { [weak self] error in
                // saveToPreferences 完成后检查是否已被取消
                if self?.disconnectRequested == true {
                    print("⚠️ WireGuardPlugin: saveConfiguration aborted after saveToPreferences")
                    completion(false, "Cancelled")
                    return
                }
                if let error = error {
                    print("❌ WireGuardPlugin: Failed to save: \(error.localizedDescription)")
                    completion(false, "Failed to save VPN configuration: \(error.localizedDescription)")
                    return
                }
                
                print("✅ WireGuardPlugin: Configuration saved successfully")
                
                // 重新加载以确保配置生效
                print("🔵 WireGuardPlugin: Reloading configuration...")
                manager.loadFromPreferences { [weak self] error in
                    // loadFromPreferences 完成后检查是否已被取消
                    if self?.disconnectRequested == true {
                        print("⚠️ WireGuardPlugin: saveConfiguration aborted after loadFromPreferences")
                        completion(false, "Cancelled")
                        return
                    }
                    if let error = error {
                        print("❌ WireGuardPlugin: Failed to reload: \(error.localizedDescription)")
                        completion(false, "Failed to reload VPN configuration: \(error.localizedDescription)")
                        return
                    }
                    
                    print("✅ WireGuardPlugin: Configuration reloaded successfully")
                    self?.vpnManager = manager
                    completion(true, nil)
                }
            }
        }
        // 注意：NETunnelProviderManager 的所有回调均在主线程执行（Apple 文档保证），
        // 因此 disconnectRequested 的读写天然在同一线程，无需额外同步。
    }
    
    private func startVPN(completion: @escaping (Bool, String?) -> Void) {
        print("🔵 WireGuardPlugin: startVPN called")
        
        // 进入 startVPN 前最后一次检查取消标志
        if disconnectRequested {
            print("⚠️ WireGuardPlugin: startVPN aborted by disconnect()")
            completion(false, "Cancelled")
            return
        }
        
        guard let manager = vpnManager else {
            print("❌ WireGuardPlugin: VPN manager is nil")
            completion(false, "VPN manager not initialized")
            return
        }
        
        print("🔵 WireGuardPlugin: VPN manager status: \(getConnectionStatus(manager.connection.status))")
        print("🔵 WireGuardPlugin: VPN manager enabled: \(manager.isEnabled)")
        print("🔵 WireGuardPlugin: Protocol configuration: \(manager.protocolConfiguration?.description ?? "nil")")
        
        if let proto = manager.protocolConfiguration as? NETunnelProviderProtocol {
            print("🔵 WireGuardPlugin: Provider bundle ID: \(proto.providerBundleIdentifier ?? "nil")")
            print("🔵 WireGuardPlugin: Server address: \(proto.serverAddress ?? "nil")")
        }
        
        print("🔵 WireGuardPlugin: Starting VPN tunnel...")
        
        do {
            try manager.connection.startVPNTunnel()
            print("✅ WireGuardPlugin: startVPNTunnel() called successfully")
            
            // 等待一小段时间后检查状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                if let status = self?.getConnectionStatus(manager.connection.status) {
                    print("📊 WireGuardPlugin: Status after 2s: \(status)")
                    if status == "disconnected" {
                        print("⚠️ WireGuardPlugin: Connection failed - returned to disconnected state")
                    }
                }
            }
            
            completion(true, nil)
        } catch {
            print("❌ WireGuardPlugin: Failed to start VPN tunnel: \(error.localizedDescription)")
            print("❌ WireGuardPlugin: Error details: \(error)")
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
