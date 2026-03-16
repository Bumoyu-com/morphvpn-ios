import UIKit
import Capacitor
import NetworkExtension
import SystemConfiguration
import WebKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var vpnManager: NETunnelProviderManager?

    // 防止重复向 JS 层派发网络就绪事件
    private var networkEventFired = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 正常初始化（Capacitor 由 Main.storyboard / CAPBridgeViewController 自动处理）
        loadVPNManager()
        stopVPNTunnel()

        // 异步探测网络权限，完成后通知 JS 层
        // 不阻塞主线程，不影响 WebView 加载速度
        probeNetworkPermission()

        return true
    }

    // MARK: - Network Permission Probe

    /// 发起一次轻量 HEAD 请求，目的是触发 iOS 首次安装时的网络权限弹窗。
    /// 请求完成（无论成功/失败/超时）即代表权限流程结束，通知 JS 层。
    private func probeNetworkPermission() {
        guard let url = URL(string: "https://captive.apple.com/hotspot-detect.html") else { return }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 8)
        request.httpMethod = "HEAD"

        let config = URLSessionConfiguration.ephemeral
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        let session = URLSession(configuration: config)

        let task = session.dataTask(with: request) { [weak self] _, _, _ in
            DispatchQueue.main.async {
                NSLog("AppDelegate: network probe completed")
                self?.dispatchNetworkReadyEvent()
            }
        }
        task.resume()

        // 兜底：10 秒后无论如何都通知 JS，防止版本检查永远不触发
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            NSLog("AppDelegate: network probe timeout fallback")
            self?.dispatchNetworkReadyEvent()
        }
    }

    /// 向 WebView 派发 'networkPermissionGranted' 事件。
    /// JS 层的 useNetworkStatus hook 监听此事件，触发版本检查等初始化逻辑。
    private func dispatchNetworkReadyEvent() {
        guard !networkEventFired else { return }
        networkEventFired = true

        guard let rootVC = window?.rootViewController else { return }
        if let webView = findWebView(in: rootVC.view) {
            webView.evaluateJavaScript(
                "window.dispatchEvent(new Event('networkPermissionGranted'))"
            ) { _, error in
                if let error = error {
                    NSLog("AppDelegate: evaluateJavaScript error: \(error)")
                } else {
                    NSLog("AppDelegate: networkPermissionGranted event dispatched")
                }
            }
        }
    }

    /// 递归查找视图层级中的 WKWebView（Capacitor 的 WebView）
    private func findWebView(in view: UIView) -> WKWebView? {
        if let webView = view as? WKWebView {
            return webView
        }
        for subview in view.subviews {
            if let found = findWebView(in: subview) {
                return found
            }
        }
        return nil
    }

    // MARK: - Lifecycle

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        beginBackgroundKeepAlive(application)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        endBackgroundKeepAlive()
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

    // MARK: - URL Handling

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return ApplicationDelegateProxy.shared.application(app, open: url, options: options)
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return ApplicationDelegateProxy.shared.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }

}