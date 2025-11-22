# ✅ 正确的 WireGuardKit 集成方式

## 🔴 之前的错误

我们之前尝试通过 **CocoaPods** 安装 WireGuardKit，但这是**错误的方式**。

## ✅ 正确的方式

根据 [官方文档](https://github.com/WireGuard/wireguard-apple)，WireGuardKit 应该通过 **Swift Package Manager (SPM)** 集成。

## 🚀 快速开始（5 个步骤）

### 1. 打开 Xcode

```bash
npx cap open ios
```

### 2. 添加 Swift Package

- 选择项目 → **Package Dependencies** 标签
- 点击 **"+"**
- 输入 URL：`https://github.com/WireGuard/wireguard-apple`
- 选择版本：**Up to Next Major Version** (1.0.0)
- 添加到 target：**WireGuardExtension** 和 **App**

### 3. 创建 WireGuardGoBridge Target

- File → New → Target → **Other** → **External Build System**
- Product Name：`WireGuardGoBridgeiOS`
- Build Tool：`/usr/bin/make`
- 配置：
  - **Directory**：`${BUILD_DIR%Build/*}SourcePackages/checkouts/wireguard-apple/Sources/WireGuardKitGo`
  - **SDKROOT**：`iphoneos`

### 4. 配置依赖

- **WireGuardExtension** target → Build Phases
- **Dependencies**：添加 `WireGuardGoBridgeiOS`
- **Link Binary With Libraries**：确认有 `WireGuardKit`

### 5. 构建和运行

- Clean Build Folder (⇧⌘K)
- Build (⌘B)
- Run (⌘R) 到真实设备

## 📚 详细步骤

参考：**`SPM_INTEGRATION_GUIDE.md`**

## ⚠️ 重要提示

1. **不要使用 CocoaPods** - WireGuardKit 不支持
2. **必须创建 WireGuardGoBridge Target** - 这是必需的
3. **必须在真实设备上测试** - 模拟器不支持 VPN
4. **Podfile 已清理** - 移除了 WireGuardKit 相关配置

## 🎯 预期结果

成功后，在 Xcode 中应该看到：

```
📦 Package Dependencies
  └── wireguard-apple
      └── WireGuardKit

🎯 Targets
  ├── App
  ├── WireGuardExtension
  └── WireGuardGoBridgeiOS
```

## 📝 文件清单

- ✅ `SPM_INTEGRATION_GUIDE.md` - 详细的集成指南
- ✅ `PacketTunnelProvider_WireGuardKit.swift` - Extension 实现代码
- ✅ `ios/App/Podfile` - 已清理（移除 WireGuardKit）

---

**准备好了吗？** 打开 `SPM_INTEGRATION_GUIDE.md` 开始集成！
