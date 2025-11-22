# MorphVPN iOS - 设置指南

## 🚀 快速开始

### 1. 安装插件

```bash
bash INSTALL_PLUGIN.sh
```

### 2. 安装 WireGuardKit

```bash
cd ios/App
pod install
cd ../..
```

### 3. 在 Xcode 中配置

```bash
npx cap open ios
```

#### 3.1 替换 PacketTunnelProvider

1. 打开 `WireGuardExtension/PacketTunnelProvider.swift`
2. 复制 `PacketTunnelProvider_WireGuardKit.swift` 的内容
3. 粘贴替换
4. 保存

#### 3.2 配置 App Groups

**在 App target**：
- Signing & Capabilities → 添加 App Groups
- 添加：`group.com.morphvpn.app`

**在 WireGuardExtension target**：
- Signing & Capabilities → 添加 App Groups
- 添加：`group.com.morphvpn.app`

### 4. 构建和运行

1. Clean Build Folder (⇧⌘K)
2. Build (⌘B)
3. Run (⌘R) 到真实 iOS 设备

## ✅ 验证

- 点击 "Test WireGuard" 按钮
- 允许 VPN 权限
- 查看 Xcode 控制台：应该看到 "✅ WireGuard: Tunnel started successfully"
- 访问 https://ifconfig.me 应该显示 VPN 服务器 IP

## 📚 详细文档

- **`WIREGUARDKIT_INTEGRATION.md`** - 完整的集成指南
- **`PacketTunnelProvider_WireGuardKit.swift`** - Extension 实现代码

## 🔧 故障排查

### pod install 失败

```bash
cd ios/App
pod repo update
pod install
cd ../..
```

### 编译错误

确保打开的是 `App.xcworkspace`，不是 `.xcodeproj`

### 连接失败

查看 Xcode 控制台的详细日志

---

**需要帮助？** 查看 `WIREGUARDKIT_INTEGRATION.md`
