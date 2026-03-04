import UIKit
import Capacitor
import NetworkExtension

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var vpnManager: NETunnelProviderManager?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 预加载 VPN manager，后续 terminate 时可直接使用，不需要异步加载
        loadVPNManager()
        // 启动时如果 VPN 还连着就断开（兜底：覆盖挂起后被杀的场景）
        stopVPNTunnel()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // 申请后台执行时间（约30秒），延长应用存活窗口。
        // 在此窗口内用户杀掉应用时 applicationWillTerminate 能被触发。
        beginBackgroundKeepAlive(application)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        endBackgroundKeepAlive()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // 路径1：用已缓存的 manager 直接同步停止（无需异步加载，最快）
        if let manager = vpnManager {
            let status = manager.connection.status
            if status == .connected || status == .connecting || status == .reasserting {
                manager.connection.stopVPNTunnel()
                NSLog("AppDelegate: [terminate] Stopped VPN via cached manager")
            }
        }

        // 路径2：写标记到 App Group，Extension 定时检测到后自行停止（双保险）
        let defaults = UserDefaults(suiteName: "group.com.morphvpn.app.wireguard")
        defaults?.set(true, forKey: "app_terminated")
        defaults?.synchronize()
        NSLog("AppDelegate: [terminate] Set app_terminated flag")
    }

    // MARK: - Background Task

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

    // MARK: - VPN Manager

    /// 预加载并缓存 VPN manager，这样 applicationWillTerminate 中可以同步使用
    private func loadVPNManager() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            self?.vpnManager = managers?.first
            if self?.vpnManager != nil {
                NSLog("AppDelegate: VPN manager cached")
            }
        }
    }

    // MARK: - VPN Cleanup

    /// 异步加载 manager 并停止 VPN，用于 didFinishLaunching 等有充足时间的场景
    private func stopVPNTunnel() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            guard let managers = managers else { return }
            for manager in managers {
                let status = manager.connection.status
                if status == .connected || status == .connecting || status == .reasserting {
                    manager.connection.stopVPNTunnel()
                    NSLog("AppDelegate: [launch] Stopped VPN tunnel")
                }
                // 顺便更新缓存
                self?.vpnManager = manager
            }

            // 启动时清除终止标记（如果有的话）
            let defaults = UserDefaults(suiteName: "group.com.morphvpn.app.wireguard")
            defaults?.removeObject(forKey: "app_terminated")
            defaults?.synchronize()
        }
    }

    // MARK: - URL / Universal Links

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return ApplicationDelegateProxy.shared.application(app, open: url, options: options)
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return ApplicationDelegateProxy.shared.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }

}
