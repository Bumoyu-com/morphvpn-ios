# 修复 "Update Required" 错误

## 🔴 问题

在 iPhone 的 **Settings → VPN & Device Management** 中显示 "Update Required"

## 🎯 原因

插件尝试创建 VPN 配置，但找不到对应的 **Network Extension**。

当前配置：
```swift
providerBundleIdentifier = "com.morphvpn.app.WireGuardExtension"
```

但这个 Network Extension target 不存在！

## ✅ 解决方案

### 方案 1: 创建 Network Extension（推荐）

这是正确的做法，可以让 VPN 真正工作。

#### 步骤 1: 在 Xcode 中创建 Network Extension

1. 打开 Xcode 项目：
   ```bash
   npx cap open ios
   ```

2. 在 Xcode 中：
   - 选择项目 → 点击 "+" 添加新 Target
   - 选择 **"Network Extension"**
   - 选择 **"Packet Tunnel Provider"**
   - 命名为：`WireGuardExtension`
   - Bundle ID：`com.morphvpn.app.WireGuardExtension`
   - 语言：Swift
   - 点击 Finish

3. Xcode 会创建：
   - `WireGuardExtension` 文件夹
   - `PacketTunnelProvider.swift` 文件
   - 自动配置 entitlements

#### 步骤 2: 实现 PacketTunnelProvider

在 `PacketTunnelProvider.swift` 中，需要实现 WireGuard 协议处理。

**简单版本（用于测试）**：

```swift
import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        NSLog("WireGuard: Starting tunnel")
        
        // 获取配置
        guard let protocolConfiguration = self.protocolConfiguration as? NETunnelProviderProtocol,
              let providerConfiguration = protocolConfiguration.providerConfiguration,
              let wgConfig = providerConfiguration["wg_config"] as? String else {
            NSLog("WireGuard: Missing configuration")
            completionHandler(NSError(domain: "WireGuard", code: 1, userInfo: nil))
            return
        }
        
        NSLog("WireGuard: Config received: \(wgConfig.prefix(50))...")
        
        // TODO: 实现 WireGuard 协议
        // 这里需要使用 WireGuardKit 或其他 WireGuard 实现
        
        // 暂时只是标记为已连接
        completionHandler(nil)
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        NSLog("WireGuard: Stopping tunnel, reason: \(reason)")
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        NSLog("WireGuard: Received app message")
        completionHandler?(nil)
    }
}
```

#### 步骤 3: 配置 App Groups（可选但推荐）

为了让主 App 和 Extension 共享数据：

1. 在主 App target 的 **Signing & Capabilities**：
   - 添加 **App Groups**
   - 添加 group：`group.com.morphvpn.app`

2. 在 WireGuardExtension target 的 **Signing & Capabilities**：
   - 添加 **App Groups**
   - 添加相同的 group：`group.com.morphvpn.app`

#### 步骤 4: 重新构建和测试

```bash
# 在 Xcode 中
# Product → Clean Build Folder (⇧⌘K)
# Product → Build (⌘B)
# 运行到设备
```

### 方案 2: 使用 WireGuardKit（完整实现）

WireGuardKit 是官方的 Swift 实现。

#### 安装 WireGuardKit

1. 在 `ios/App/Podfile` 中添加：
   ```ruby
   target 'WireGuardExtension' do
     pod 'WireGuardKit', '~> 1.0'
   end
   ```

2. 运行：
   ```bash
   cd ios/App
   pod install
   cd ../..
   ```

3. 在 `PacketTunnelProvider.swift` 中使用 WireGuardKit

### 方案 3: 临时禁用（仅用于测试 UI）

如果你只想测试 UI，暂时不需要真正的 VPN 连接：

#### 修改插件代码

在 `packages/wireguard-plugin/ios/Plugin/WireGuardPlugin.swift` 中：

```swift
@objc func connect(_ call: CAPPluginCall) {
    print("🔵 WireGuardPlugin: connect() called")
    
    // 临时：直接返回成功，不实际创建 VPN
    call.resolve(["success": true, "message": "VPN connection simulated (Network Extension not implemented)"])
}
```

然后重新构建插件：
```bash
bash INSTALL_PLUGIN.sh
npx cap sync ios
```

## 🔍 验证 Network Extension

### 检查 Bundle ID

在 Xcode 中：
1. 选择 WireGuardExtension target
2. 查看 **General → Bundle Identifier**
3. 应该是：`com.morphvpn.app.WireGuardExtension`

### 检查 Entitlements

在 WireGuardExtension target 的 entitlements 中应该有：

```xml
<key>com.apple.developer.networking.networkextension</key>
<array>
    <string>packet-tunnel-provider</string>
</array>
```

### 检查签名

确保两个 target 都正确签名：
- App target
- WireGuardExtension target

## 📱 清除旧的 VPN 配置

如果之前创建了错误的 VPN 配置：

1. 在 iPhone 上：
   - Settings → General → VPN & Device Management
   - 找到 MorphVPN 或 TestVPN
   - 删除配置

2. 重新安装应用

## 🎯 推荐步骤

1. **创建 Network Extension target**（方案 1）
2. **使用简单的 PacketTunnelProvider**（先测试连接）
3. **验证 VPN 配置可以创建**
4. **集成 WireGuardKit**（实现真正的 VPN）

## 📚 参考资源

- [Apple Network Extension 文档](https://developer.apple.com/documentation/networkextension)
- [WireGuard iOS 官方实现](https://git.zx2c4.com/wireguard-apple)
- [WireGuardKit GitHub](https://github.com/passepartoutvpn/wireguard-apple)

## ⚠️ 重要提示

- Network Extension 必须在 Xcode 中创建，无法通过命令行
- 需要正确的签名和 provisioning profile
- 测试时必须使用真实设备
- 首次运行会请求 VPN 权限

---

**下一步**：在 Xcode 中创建 Network Extension target
