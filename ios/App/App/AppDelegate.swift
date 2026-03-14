import UIKit
import Capacitor
import NetworkExtension
import SystemConfiguration

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var vpnManager: NETunnelProviderManager?
    
    // 新增：网络权限检测相关
    private var hasCheckedNetworkPermission = false
    private var bridgeViewController: CAPBridgeViewController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 新增：先检测网络权限，再初始化 Capacitor 和 VPN
        checkNetworkPermissionAndInitialize()
        
        return true
    }

    // MARK: - Network Permission & Initialization (新增)

    /// 检测网络权限状态，确保权限弹窗完成后再初始化
    private func checkNetworkPermissionAndInitialize() {
        // 方法1：尝试触发网络权限弹窗并检测响应
        let testURL = URL(string: "https://www.apple.com")!
        var request = URLRequest(url: testURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 5)
        request.httpMethod = "HEAD"
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        let session = URLSession(configuration: config)
        
        let task = session.dataTask(with: request) { [weak self] _, response, error in
            DispatchQueue.main.async {
                self?.hasCheckedNetworkPermission = true
                
                // 无论成功失败，说明网络权限流程已完成
                NSLog("AppDelegate: Network permission check completed")
                
                // 现在可以安全地初始化 Capacitor 和 VPN
                self?.initializeApp()
            }
        }
        
        task.resume()
        
        // 兜底：3秒后无论权限如何都强制初始化（避免卡死）
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self, !self.hasCheckedNetworkPermission else { return }
            NSLog("AppDelegate: Network permission timeout, forcing initialization")
            self.hasCheckedNetworkPermission = true
            self.initializeApp()
        }
    }
    
    /// 初始化应用（Capacitor + VPN）
    private func initializeApp() {
        // 1. 先初始化 Capacitor Bridge
        setupCapacitor()
        
        // 2. 再初始化 VPN（确保网络栈已就绪）
        loadVPNManager()
        stopVPNTunnel()
    }
    
    /// 设置 Capacitor WebView
    private func setupCapacitor() {
        bridgeViewController = CAPBridgeViewController()
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = bridgeViewController
        window?.makeKeyAndVisible()
        NSLog("AppDelegate: Capacitor initialized")
    }

    // MARK: - Lifecycle (原有逻辑)

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        beginBackgroundKeepAlive(application)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        endBackgroundKeepAlive()
        
        // 新增：从后台返回时检查网络是否恢复（处理首次授权后的情况）
        if hasCheckedNetworkPermission {
            notifyNetworkMayBeAvailable()
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
        if let manager = vpnManager {
            let status = manager.connection.status
            if status == .connected || status == .connecting || status == .reasserting {
                manager.connection.stopVPNTunnel()
                NSLog("AppDelegate: [terminate] Stopped VPN via cached manager")
            }
        }

        let defaults = UserDefaults(suiteName: "group.com.morphvpn.app.wireguard")
        defaults?.set(true, forKey: "app_terminated")
        defaults?.synchronize()
        NSLog("AppDelegate: [terminate] Set app_terminated flag")
    }

    // MARK: - Background Task (原有逻辑)

    private func beginBackgroundKeepAlive(_ application: UIApplication) {
        endBackgroundKeepAlive()
        backgroundTaskID = application.beginBackgroundTask(withName: "VPNKeepAlive") { [weak self] in
            self?.endBackgroundKeepAlive()
        }
    }

    private func endBackgroundKeepAlive() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }

    // MARK: - VPN Manager (修改：移除重复初始化)

    private func loadVPNManager() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            self?.vpnManager = managers?.first
            if self?.vpnManager != nil {
                NSLog("AppDelegate: VPN manager cached")
            }
        }
    }

    private func stopVPNTunnel() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            guard let managers = managers else { return }
            for manager in managers {
                let status = manager.connection.status
                if status == .connected || status == .connecting || status == .reasserting {
                    manager.connection.stopVPNTunnel()
                    NSLog("AppDelegate: [launch] Stopped VPN tunnel")
                }
                self?.vpnManager = manager
            }

            let defaults = UserDefaults(suiteName: "group.com.morphvpn.app.wireguard")
            defaults?.removeObject(forKey: "app_terminated")
            defaults?.synchronize()
        }
    }

    // MARK: - Network Recovery Notification (修复：使用 NotificationCenter)

    /// 通知 JS 层网络可能已恢复（用于首次授权后）
    private func notifyNetworkMayBeAvailable() {
        // 延迟一点确保网络栈完全就绪
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            // 方法1：通过 NotificationCenter 发送通知（推荐）
            NotificationCenter.default.post(
                name: NSNotification.Name("networkPermissionGranted"), 
                object: nil
            )
            
            // 方法2：如果需要在 JS 层监听，可以通过 App 插件转发
            // 或者使用 Capacitor 的 App 插件的 appUrlOpen 等机制
            
            NSLog("AppDelegate: Notified network permission granted")
        }
    }

    // MARK: - URL Handling (原有逻辑)

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return ApplicationDelegateProxy.shared.application(app, open: url, options: options)
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return ApplicationDelegateProxy.shared.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }

}