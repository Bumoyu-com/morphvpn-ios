# MorphVPN iOS - 设置指南

## 🚀 快速开始

### 1. 安装插件

```bash
bash INSTALL_PLUGIN.sh
```

### 2. 集成 WireGuardKit (Swift Package Manager)

```bash
npx cap open ios
```

#### 2.1 添加 Swift Package

1. 在 Xcode 中，选择项目
2. 切换到 **Package Dependencies** 标签
3. 点击 **"+"** 按钮
4. 输入 URL：`https://github.com/WireGuard/wireguard-apple`
5. 选择版本：**Up to Next Major Version** (1.0.0)
6. 添加到 target：**WireGuardExtension** 和 **App**

#### 2.2 创建 WireGuardGoBridge Target

1. File → New → Target → **Other** → **External Build System**
2. Product Name：`WireGuardGoBridgeiOS`
3. Build Tool：`/usr/bin/make`
4. 配置 Info → Directory：
   ```
   ${BUILD_DIR%Build/*}SourcePackages/checkouts/wireguard-apple/Sources/WireGuardKitGo
   ```
5. Build Settings → SDKROOT：`iphoneos`

#### 2.3 配置依赖

1. **WireGuardExtension** target → Build Phases
2. **Dependencies**：添加 `WireGuardGoBridgeiOS`
3. **Link Binary With Libraries**：确认有 `WireGuardKit`

### 3. 替换 PacketTunnelProvider

1. 打开 `WireGuardExtension/PacketTunnelProvider.swift`
2. 复制 `PacketTunnelProvider_WireGuardKit.swift` 的内容
3. 粘贴替换
4. 保存

### 4. 配置 App Groups

**在 App target**：
- Signing & Capabilities → 添加 App Groups
- 添加：`group.com.morphvpn.app`

**在 WireGuardExtension target**：
- Signing & Capabilities → 添加 App Groups
- 添加：`group.com.morphvpn.app`

### 5. 禁用 Bitcode (iOS only)

在 **App** 和 **WireGuardExtension** target：
- Build Settings → Enable Bitcode → **No**

### 6. 构建和运行

1. Clean Build Folder (⇧⌘K)
2. Build (⌘B)
3. Run (⌘R) 到真实 iOS 设备

## ✅ 验证

- 点击 "Test WireGuard" 按钮
- 允许 VPN 权限
- 查看 Xcode 控制台：应该看到 "✅ WireGuard: Tunnel started successfully"
- 访问 https://ifconfig.me 应该显示 VPN 服务器 IP

## 📚 详细文档

- **`CORRECT_WAY.md`** ⭐ - 正确的集成方式
- **`SPM_INTEGRATION_GUIDE.md`** ⭐ - 详细的 SPM 集成步骤
- **`PacketTunnelProvider_WireGuardKit.swift`** - Extension 实现代码

## 🔧 故障排查

### 无法添加 Swift Package

重启 Xcode 并清理 Derived Data：
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### WireGuardGoBridge 构建失败

确认 Directory 路径和 SDKROOT 设置正确

### 编译错误 "No such module 'WireGuardKit'"

File → Packages → Reset Package Caches

---

**需要帮助？** 查看 `SPM_INTEGRATION_GUIDE.md`
