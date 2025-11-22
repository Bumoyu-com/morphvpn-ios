# "Update Required" 快速修复指南

## 🔴 问题

iPhone 的 **Settings → VPN & Device Management** 显示 "Update Required"

## 🎯 原因

缺少 **Network Extension** target

## ✅ 解决方案（5 分钟）

### 1. 打开 Xcode

```bash
npx cap open ios
```

### 2. 创建 Network Extension

1. 选择项目 → 点击 "+" 添加 Target
2. 选择 **Network Extension** → **Packet Tunnel Provider**
3. 命名：`WireGuardExtension`
4. Bundle ID：`com.morphvpn.app.WireGuardExtension`
5. 点击 Finish

### 3. 替换代码

1. 打开 `WireGuardExtension/PacketTunnelProvider.swift`
2. 复制项目根目录的 `PacketTunnelProvider_Template.swift` 内容
3. 粘贴替换
4. 保存

### 4. 配置 Entitlements

1. 右键 WireGuardExtension 文件夹 → New File → Property List
2. 命名：`WireGuardExtension.entitlements`
3. 复制项目根目录的 `WireGuardExtension.entitlements` 内容
4. 粘贴
5. 在 target 设置中关联这个文件

### 5. 添加 Capabilities

在 **WireGuardExtension** target 的 **Signing & Capabilities**：
- 添加 **Network Extensions**（勾选 Packet Tunnel）
- 添加 **App Groups**（添加 `group.com.morphvpn.app`）

在 **App** target 中也添加相同的 **App Groups**

### 6. 构建和运行

1. Clean Build Folder (⇧⌘K)
2. Build (⌘B)
3. Run (⌘R)

## ✅ 验证

- Settings → VPN & Device Management 不再显示 "Update Required"
- 可以看到 "Connected" 或 "Not Connected" 状态
- Xcode 控制台显示：`🟢 WireGuard Extension: Starting tunnel`

## 📚 详细指南

参考 `CREATE_NETWORK_EXTENSION.md` 获取完整的分步说明。

## ⚠️ 重要

当前实现是**简化版本**，可以创建 VPN 配置但不会实际传输流量。

要实现真正的 VPN，需要集成 WireGuardKit。

---

**需要帮助？** 查看 `FIX_UPDATE_REQUIRED.md`
