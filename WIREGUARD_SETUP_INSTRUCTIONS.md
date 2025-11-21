# WireGuard 插件设置说明

## 已完成的修改 ✅

1. **更新了 WireGuard 配置** (`src/components/TestVpn.tsx`)
   - 使用了提供的真实配置参数
   - 添加了 antd message 提示替代 console.log
   - 改进了错误处理

2. **添加了插件文件到 Xcode 项目**
   - WireGuardPlugin.swift
   - WireGuardPlugin.m

3. **添加了必要的权限配置**
   - Info.plist: 添加了网络访问权限说明
   - App.entitlements: 添加了 VPN 和 Network Extension 权限

## ⚠️ 重要：还需要完成的步骤

### 1. 创建 Network Extension Target

WireGuard 需要一个 **Network Extension** 来实际处理 VPN 连接。这必须在 Xcode 中手动创建：

#### 在 Xcode 中操作：

1. 打开 `ios/App/App.xcodeproj`
2. 选择项目 → 点击 "+" 添加新 Target
3. 选择 "Network Extension" → "Packet Tunnel Provider"
4. 命名为 `WireGuardExtension`
5. Bundle ID 应该是: `com.morphvpn.app.WireGuardExtension`

#### 更新 WireGuardPlugin.swift 中的 Bundle ID：

在 `ios/App/App/Plugins/WireGuardPlugin.swift` 第 199 行：

```swift
// 当前是占位符，需要替换为实际的 Bundle ID
providerProtocol.providerBundleIdentifier = "com.example.app.WireGuardExtension"

// 应该改为：
providerProtocol.providerBundleIdentifier = "com.morphvpn.app.WireGuardExtension"
```

### 2. 实现 Network Extension 的 PacketTunnelProvider

在新创建的 Network Extension target 中，需要实现 WireGuard 协议处理逻辑。

参考文件：
- [WireGuard iOS 官方实现](https://git.zx2c4.com/wireguard-apple)
- 或使用 WireGuardKit framework

### 3. 配置 App Groups（可选但推荐）

为了让主 App 和 Network Extension 共享数据：

1. 在 Xcode 中为两个 target 都启用 App Groups
2. 添加相同的 group ID，例如：`group.com.morphvpn.app`
3. 更新 entitlements 文件

### 4. 在真机上测试

⚠️ **VPN 功能只能在真实 iOS 设备上测试，模拟器不支持！**

测试步骤：
1. 连接 iOS 设备
2. 在 Xcode 中选择你的设备
3. 构建并运行
4. 首次运行时，系统会请求 VPN 权限
5. 点击登录页面的 "Test WireGuard" 按钮

## 当前配置信息

```
Endpoint: 65.20.89.15:51820
Interface Address: 10.8.0.2/24
DNS: 1.1.1.1
```

## 错误排查

### "plugin is not implemented on ios"

这个错误说明插件文件没有正确编译到 App 中。已通过修改 `project.pbxproj` 解决。

### 连接失败

可能的原因：
1. Network Extension target 未创建或未正确配置
2. Bundle ID 不匹配
3. 权限未授予
4. WireGuard 服务器配置问题

### 查看日志

在真机上调试时，可以通过以下方式查看日志：
1. Xcode → Window → Devices and Simulators
2. 选择设备 → View Device Logs
3. 或使用 Console.app 查看系统日志

## 参考资源

- [Capacitor iOS Plugin Guide](https://capacitorjs.com/docs/plugins/ios)
- [Apple Network Extension Documentation](https://developer.apple.com/documentation/networkextension)
- [WireGuard Protocol](https://www.wireguard.com/protocol/)
