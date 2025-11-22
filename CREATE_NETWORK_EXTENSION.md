# 创建 Network Extension - 分步指南

## 🎯 目标

创建 Network Extension target 来修复 "Update Required" 错误。

## 📋 准备工作

确保你已经：
- ✅ 安装了插件（运行过 `bash INSTALL_PLUGIN.sh`）
- ✅ 在 Mac 上打开了 Xcode
- ✅ 连接了 iOS 设备

## 🚀 步骤 1: 打开 Xcode 项目

```bash
npx cap open ios
```

## 📱 步骤 2: 创建 Network Extension Target

### 2.1 添加新 Target

1. 在 Xcode 左侧，选择项目（蓝色图标）
2. 在编辑器区域，点击左下角的 **"+"** 按钮
3. 或者：菜单栏 → **File** → **New** → **Target...**

### 2.2 选择模板

1. 在弹出的窗口中，选择 **iOS** 标签
2. 滚动找到 **"Network Extension"**
3. 选择 **"Packet Tunnel Provider"**
4. 点击 **Next**

### 2.3 配置 Target

填写以下信息：

- **Product Name**: `WireGuardExtension`
- **Team**: 选择你的开发团队
- **Organization Identifier**: `com.morphvpn`
- **Bundle Identifier**: 应该自动生成为 `com.morphvpn.app.WireGuardExtension`
- **Language**: Swift
- **Project**: App
- **Embed in Application**: App

点击 **Finish**

### 2.4 激活 Scheme（如果提示）

如果 Xcode 询问是否激活新的 scheme，点击 **Activate**

## 📝 步骤 3: 替换 PacketTunnelProvider 代码

### 3.1 找到文件

在 Xcode 左侧，展开 **WireGuardExtension** 文件夹，找到 `PacketTunnelProvider.swift`

### 3.2 替换内容

1. 打开项目根目录的 `PacketTunnelProvider_Template.swift`
2. 复制全部内容
3. 粘贴到 Xcode 中的 `PacketTunnelProvider.swift`，替换原有内容
4. 保存（⌘S）

## 🔐 步骤 4: 配置 Entitlements

### 4.1 添加 Entitlements 文件

1. 在 Xcode 左侧，右键点击 **WireGuardExtension** 文件夹
2. 选择 **New File...**
3. 选择 **Property List**
4. 命名为：`WireGuardExtension.entitlements`
5. 点击 **Create**

### 4.2 配置 Entitlements 内容

1. 打开项目根目录的 `WireGuardExtension.entitlements`
2. 复制内容
3. 在 Xcode 中打开刚创建的 `WireGuardExtension.entitlements`
4. 切换到 **Source Code** 视图（右键点击文件 → Open As → Source Code）
5. 粘贴内容
6. 保存

### 4.3 关联 Entitlements 文件

1. 在 Xcode 左侧，选择项目（蓝色图标）
2. 选择 **WireGuardExtension** target
3. 选择 **Signing & Capabilities** 标签
4. 在 **Signing** 部分，找到 **Code Signing Entitlements**
5. 设置为：`WireGuardExtension/WireGuardExtension.entitlements`

## 🔧 步骤 5: 配置 Capabilities

### 5.1 添加 Network Extensions

在 **WireGuardExtension** target 的 **Signing & Capabilities** 标签：

1. 点击 **+ Capability**
2. 搜索并添加 **Network Extensions**
3. 确保勾选了 **Packet Tunnel**

### 5.2 添加 App Groups（可选但推荐）

1. 点击 **+ Capability**
2. 搜索并添加 **App Groups**
3. 点击 **+** 添加新 group
4. 输入：`group.com.morphvpn.app`
5. 勾选这个 group

**同时在主 App target 中也添加相同的 App Group**：

1. 选择 **App** target
2. 在 **Signing & Capabilities** 中添加 **App Groups**
3. 添加相同的 group：`group.com.morphvpn.app`

## 🔨 步骤 6: 构建和测试

### 6.1 清理构建

1. 菜单栏 → **Product** → **Clean Build Folder** (⇧⌘K)

### 6.2 构建项目

1. 选择 **App** scheme（不是 WireGuardExtension）
2. 选择你的 iOS 设备
3. 点击 **Build** (⌘B)

### 6.3 运行到设备

1. 点击 **Run** (⌘R)
2. 等待应用安装并启动

## ✅ 步骤 7: 验证

### 7.1 在应用中测试

1. 进入登录页面
2. 点击 **"Test WireGuard"** 按钮
3. 首次运行会弹出 VPN 权限请求，点击 **Allow**

### 7.2 检查 VPN 配置

在 iPhone 上：
1. Settings → General → VPN & Device Management
2. 应该看到 **TestVPN** 配置
3. 状态应该是 **Connected** 或 **Not Connected**（不再是 "Update Required"）

### 7.3 查看日志

在 Xcode 的控制台中，应该看到：

```
✅ WireGuardPlugin: Plugin loaded successfully
🔵 WireGuardPlugin: connect() called
🟢 WireGuard Extension: Starting tunnel
✅ WireGuard Extension: Network settings applied
```

## 🎉 成功标志

- ✅ 应用可以创建 VPN 配置
- ✅ 不再显示 "Update Required"
- ✅ 可以看到 "Connected" 或 "Not Connected" 状态
- ✅ Xcode 日志显示 Extension 正在运行

## ⚠️ 注意事项

### 当前实现的限制

这个 PacketTunnelProvider 是一个**简化版本**：

- ✅ 可以创建 VPN 配置
- ✅ 可以应用网络设置
- ❌ **不会实际传输 VPN 流量**（需要集成 WireGuardKit）

### 下一步

要实现真正的 WireGuard VPN，需要：

1. 集成 WireGuardKit
2. 实现 WireGuard 协议处理
3. 处理密钥交换和加密

参考：`WIREGUARD_SETUP_INSTRUCTIONS.md`

## 🔧 故障排查

### 问题 1: 找不到 Network Extension 模板

**解决**：确保 Xcode 版本 ≥ 12.0

### 问题 2: Bundle ID 冲突

**解决**：确保 Bundle ID 是 `com.morphvpn.app.WireGuardExtension`

### 问题 3: 签名错误

**解决**：
1. 选择正确的开发团队
2. 确保两个 target 都正确签名
3. 可能需要在 Apple Developer 网站创建 App ID

### 问题 4: 仍然显示 "Update Required"

**解决**：
1. 删除旧的 VPN 配置（Settings → VPN & Device Management）
2. 卸载应用
3. 重新构建和安装
4. 重新测试

### 问题 5: Extension 没有运行

**解决**：
1. 检查 Xcode 控制台是否有错误
2. 确保 entitlements 配置正确
3. 确保 Bundle ID 匹配插件中的配置

## 📞 需要帮助？

如果遇到问题：

1. 查看 Xcode 控制台的完整日志
2. 检查 Settings → VPN & Device Management 中的配置状态
3. 确认 Bundle ID 是否正确：`com.morphvpn.app.WireGuardExtension`

---

**准备好了吗？** 打开 Xcode 开始创建 Network Extension！
