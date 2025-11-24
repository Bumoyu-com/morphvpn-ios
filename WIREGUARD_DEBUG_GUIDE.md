# WireGuard 连接调试指南

## 📋 已修复的问题

### 1. ✅ PacketTunnelProvider 增强
- 添加了详细的日志输出
- 添加了错误处理和错误信息
- 使用 os.log 进行系统级日志记录

### 2. ✅ 配置扩展文件
- 添加了 `TunnelConfiguration+WgQuickConfig.swift`
- 添加了 `String+ArrayConversion.swift`

### 3. ✅ App Groups 配置修复
- 统一了主 App 和 Extension 的 App Groups 配置
- 使用 `group.com.morphvpn.app.wireguard`

### 4. ✅ WireGuard 配置优化
- 修改 `PersistentKeepalive` 从 0 到 25
- 添加了详细的日志输出

### 5. ✅ 插件日志增强
- WireGuardPlugin.swift 添加了详细的调试日志
- 可以追踪配置传递的每一步

## 🔍 如何查看日志

### 方法 1: Xcode Console（推荐）

1. 在 Xcode 中运行应用
2. 打开底部的 Console 面板
3. 点击 "Test WireGuard" 按钮
4. 观察日志输出

**预期日志流程**：

```
// React 层
🔵 VPNComponent: handleConnect called
🔵 Platform: ios
🔵 Config length: 300
🔵 Calling connect...

// Swift Plugin 层
🔵 WireGuardPlugin: connect() called
🔵 WireGuardPlugin: Config received
🔵 WireGuardPlugin: Tunnel name: MorphVPN
🔵 WireGuardPlugin: Config length: 300 bytes
🔵 WireGuardPlugin: saveConfiguration called
🔵 WireGuardPlugin: Provider bundle ID: com.morphvpn.app.WireGuardExtension
🔵 WireGuardPlugin: Provider configuration set with wg_config key
🔵 WireGuardPlugin: Saving VPN configuration to preferences...
✅ WireGuardPlugin: Configuration saved successfully
🔵 WireGuardPlugin: Reloading configuration...
✅ WireGuardPlugin: Configuration reloaded successfully
🔵 WireGuardPlugin: startVPN called
🔵 WireGuardPlugin: VPN manager status: disconnected
🔵 WireGuardPlugin: Starting VPN tunnel...
✅ WireGuardPlugin: startVPNTunnel() called successfully

// Network Extension 层
🚀 Starting WireGuard tunnel...
✅ Got WireGuard config, length: 300 bytes
✅ Successfully parsed WireGuard configuration
Creating WireGuard adapter...
Starting WireGuard adapter...
✅ WireGuard tunnel started successfully!
```

### 方法 2: Console.app（查看 Network Extension 日志）

1. 打开 macOS 的 **Console.app**
2. 连接你的 iOS 设备
3. 在左侧选择你的设备
4. 在搜索框输入：`WireGuard` 或 `PacketTunnel`
5. 点击 "Test WireGuard" 按钮
6. 查看实时日志

## 🐛 常见问题和解决方案

### 问题 1: "Missing required parameters"
**症状**：配置或隧道名称没有正确传递
**解决**：检查 React 代码中的 `connect(myConfig, 'MorphVPN')` 调用

### 问题 2: "Invalid protocol configuration"
**症状**：Network Extension 配置不正确
**解决**：检查 Bundle ID 是否为 `com.morphvpn.app.WireGuardExtension`

### 问题 3: "Failed to parse WireGuard config"
**症状**：WireGuard 配置格式错误
**解决**：检查配置中的密钥格式（Base64）和 Endpoint 格式

### 问题 4: "VPN configuration is not allowed"
**症状**：VPN 配置保存失败
**解决**：确保在真机上测试，检查 Capabilities 配置

## 📱 在设备上测试

### 必需条件
- ✅ 真实 iOS 设备（不能用模拟器）
- ✅ 有效的开发者证书
- ✅ 正确的 Provisioning Profile
- ✅ 网络连接

### 测试流程

1. **构建并安装**
   ```bash
   # 在 Xcode 中
   Product → Clean Build Folder (⇧⌘K)
   Product → Build (⌘B)
   Product → Run (⌘R)
   ```

2. **首次运行**
   - App 会请求 VPN 权限
   - 点击 "允许"
   - 可能需要输入设备密码

3. **点击 "Test WireGuard"**
   - 观察 Xcode Console 日志
   - 观察设备状态栏（VPN 图标）

## 🎯 成功标志

当一切正常时，你应该看到：

### Xcode Console
```
✅ WireGuardPlugin: Configuration saved successfully
✅ WireGuardPlugin: startVPNTunnel() called successfully
✅ WireGuard tunnel started successfully!
```

### iOS 设备
- 状态栏显示 VPN 图标
- 设置中 VPN 状态显示 "已连接"

### React UI
- 状态显示 "connected"
- 按钮变为 "Disconnect WireGuard"
