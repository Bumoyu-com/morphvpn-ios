# Xcode 项目验证清单

## 🔍 问题诊断结果

### 从 123.txt 日志分析：

#### ✅ 正常的部分
1. ✅ WireGuardPlugin 加载成功
2. ✅ 配置格式正确：`[Interface]` (单括号)
3. ✅ PersistentKeepalive = 25 (正确)
4. ✅ 配置保存成功
5. ✅ startVPNTunnel() 调用成功
6. ✅ Bundle ID 正确：com.morphvpn.app.WireGuardExtension

#### ❌ 问题所在
**核心问题：PacketTunnelProvider 完全没有被调用！**

日志中应该看到但没有看到的：
```
🎯 PacketTunnelProvider: init() called          ← 缺失！
🚀 PacketTunnelProvider: startTunnel() called   ← 缺失！
```

状态变化：
```
connecting → connecting → disconnecting → disconnected
```

这说明 iOS 系统尝试启动 Extension，但 Extension 没有响应。

## 📋 必须检查的配置项

### 1. ⚠️ App Groups 配置不一致

**当前状态**：
- App.entitlements: `group.com.morphvpn.app`
- WireGuardExtension.entitlements: `group.com.morphvpn.app`
- keychain-access-groups: `group.com.morphvpn.app.wireguard`

**问题**：App Groups 名称不统一！

**修复方案**：统一使用 `group.com.morphvpn.app.wireguard`

#### 修复步骤：

**1.1 修改 App.entitlements**
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.morphvpn.app.wireguard</string>  ← 改为这个
</array>
```

**1.2 修改 WireGuardExtension.entitlements**
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.morphvpn.app.wireguard</string>  ← 改为这个
</array>
```

**1.3 在 Xcode 中同步**
```
1. 打开 Xcode: npx cap open ios
2. 选择 App target
3. Signing & Capabilities
4. App Groups
5. 确认勾选: group.com.morphvpn.app.wireguard
6. 如果没有，点击 + 添加

7. 选择 WireGuardExtension target
8. Signing & Capabilities
9. App Groups
10. 确认勾选: group.com.morphvpn.app.wireguard
```

### 2. ✅ Extension 嵌入配置（已正确）

**检查项**：
- [x] WireGuardExtension.appex 在 Embed Foundation Extensions 中
- [x] 设置为 RemoveHeadersOnCopy

### 3. ✅ Bundle Identifier（已正确）

**检查项**：
- [x] App: com.morphvpn.app
- [x] Extension: com.morphvpn.app.WireGuardExtension

### 4. ⚠️ Scheme 配置（需要在 Xcode 中检查）

**检查步骤**：
```
Product → Scheme → Edit Scheme
→ Build
→ 找到 WireGuardExtension
→ 确认以下选项都已勾选：
   ✓ Build
   ✓ Run
   ✓ Test
   ✓ Profile
   ✓ Archive
   ✓ Analyze
```

### 5. ⚠️ Target Dependencies（需要在 Xcode 中检查）

**检查步骤**：
```
选择 App target
→ Build Phases
→ Dependencies
→ 确认包含：WireGuardExtension
```

### 6. ⚠️ WireGuardExtension 的 Frameworks（需要在 Xcode 中检查）

**检查步骤**：
```
选择 WireGuardExtension target
→ General
→ Frameworks and Libraries
→ 确认包含：
   ✓ WireGuardKit (from Swift Package)
   ✓ NetworkExtension.framework
   ✓ libwg-go.a
```

### 7. ⚠️ Info.plist 配置（需要验证）

**检查步骤**：
```
打开 ios/App/WireGuardExtension/Info.plist
确认包含：
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.networkextension.packet-tunnel</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).PacketTunnelProvider</string>
</dict>
```

### 8. ⚠️ Code Signing（需要在 Xcode 中检查）

**检查步骤**：
```
选择 App target
→ Signing & Capabilities
→ 确认：
   ✓ Automatically manage signing (勾选)
   ✓ Team: 选择你的开发团队
   ✓ Provisioning Profile: 自动生成

选择 WireGuardExtension target
→ Signing & Capabilities
→ 确认：
   ✓ Automatically manage signing (勾选)
   ✓ Team: 与 App 相同
   ✓ Provisioning Profile: 自动生成
```

### 9. ⚠️ Capabilities（需要在 Xcode 中检查）

**App target 需要的 Capabilities**：
```
✓ Network Extensions
✓ App Groups (group.com.morphvpn.app.wireguard)
✓ Personal VPN (自动添加)
```

**WireGuardExtension target 需要的 Capabilities**：
```
✓ Network Extensions
✓ App Groups (group.com.morphvpn.app.wireguard)
```

### 10. ⚠️ Build Settings（需要在 Xcode 中检查）

**WireGuardExtension target**：
```
选择 WireGuardExtension target
→ Build Settings
→ 搜索并确认：

Skip Install: NO
Product Bundle Identifier: com.morphvpn.app.WireGuardExtension
Code Signing Entitlements: WireGuardExtension/WireGuardExtension.entitlements
Deployment Target: 14.0 或更高
```

## 🔧 完整修复步骤

### 步骤 1: 修复 App Groups

**1.1 修改 App.entitlements**
```bash
# 编辑文件
nano ios/App/App/App.entitlements

# 将 group.com.morphvpn.app 改为 group.com.morphvpn.app.wireguard
```

**1.2 修改 WireGuardExtension.entitlements**
```bash
# 编辑文件
nano ios/App/WireGuardExtension/WireGuardExtension.entitlements

# 将 group.com.morphvpn.app 改为 group.com.morphvpn.app.wireguard
```

### 步骤 2: 在 Xcode 中验证配置

```bash
# 打开 Xcode
npx cap open ios
```

#### 2.1 检查 Scheme
```
Product → Scheme → Edit Scheme
→ Build
→ 确认 WireGuardExtension 已勾选
```

#### 2.2 检查 App target
```
选择 App target
→ General
→ Frameworks, Libraries, and Embedded Content
→ 确认 WireGuardExtension.appex 存在且设置为 "Embed & Sign"

→ Build Phases
→ Dependencies
→ 确认包含 WireGuardExtension

→ Signing & Capabilities
→ App Groups
→ 确认勾选 group.com.morphvpn.app.wireguard
```

#### 2.3 检查 WireGuardExtension target
```
选择 WireGuardExtension target
→ General
→ Frameworks and Libraries
→ 确认包含：
   - WireGuardKit
   - NetworkExtension.framework
   - libwg-go.a

→ Signing & Capabilities
→ App Groups
→ 确认勾选 group.com.morphvpn.app.wireguard

→ Build Settings
→ 确认 Bundle Identifier: com.morphvpn.app.WireGuardExtension
```

### 步骤 3: 清理并重新构建

```
Product → Clean Build Folder (⇧⌘K)
Product → Build (⌘B)
```

### 步骤 4: 在真机上测试

```
Product → Run (⌘R)
```

**重要**：必须在真机上测试！模拟器不支持 Network Extension。

### 步骤 5: 查看日志

#### 5.1 Xcode Console
应该看到：
```
🎯 PacketTunnelProvider: init() called
🚀 PacketTunnelProvider: startTunnel() called
📦 Getting protocol configuration...
✅ Got protocol configuration
✅ Got WireGuard config, length: 316 bytes
📄 Config content: [完整配置]
🔧 Parsing WireGuard configuration...
✅ Successfully parsed WireGuard configuration
🔨 Creating WireGuard adapter...
✅ WireGuard adapter created
🚀 Starting WireGuard adapter...
✅ WireGuard tunnel started successfully!
```

#### 5.2 Console.app
```
1. 打开 macOS 的 Console.app
2. 连接 iOS 设备
3. 选择设备
4. 搜索 "PacketTunnelProvider"
5. 点击 "Test WireGuard"
6. 查看实时日志
```

## 🎯 诊断流程

```
点击 "Test WireGuard"
    ↓
✅ startVPNTunnel() called successfully
    ↓
📡 VPN status changed to: connecting
    ↓
    ├─→ 看到 "PacketTunnelProvider: init()" ✅
    │       ↓
    │   Extension 正常启动
    │       ↓
    │   问题解决！
    │
    └─→ 看不到 PacketTunnelProvider 日志 ❌
            ↓
        Extension 没有启动
            ↓
        检查：
        1. App Groups 是否一致
        2. Scheme 配置
        3. Extension 是否正确嵌入
        4. Capabilities 是否正确
        5. Code Signing 是否正确
```

## 📝 快速检查清单

在 Xcode 中逐项检查：

### App target
- [ ] Signing & Capabilities → App Groups → group.com.morphvpn.app.wireguard ✓
- [ ] Signing & Capabilities → Network Extensions ✓
- [ ] General → Frameworks → WireGuardExtension.appex (Embed & Sign) ✓
- [ ] Build Phases → Dependencies → WireGuardExtension ✓
- [ ] Signing → Team 已选择 ✓

### WireGuardExtension target
- [ ] Signing & Capabilities → App Groups → group.com.morphvpn.app.wireguard ✓
- [ ] Signing & Capabilities → Network Extensions ✓
- [ ] General → Frameworks → WireGuardKit ✓
- [ ] General → Frameworks → NetworkExtension.framework ✓
- [ ] General → Frameworks → libwg-go.a ✓
- [ ] Build Settings → Bundle Identifier → com.morphvpn.app.WireGuardExtension ✓
- [ ] Build Settings → Skip Install → NO ✓
- [ ] Signing → Team 已选择 ✓

### Scheme
- [ ] Product → Scheme → Edit Scheme → Build → WireGuardExtension 已勾选 ✓

### 文件
- [ ] ios/App/WireGuardExtension/PacketTunnelProvider.swift 存在 ✓
- [ ] ios/App/WireGuardExtension/Info.plist 配置正确 ✓
- [ ] ios/App/WireGuardExtension/WireGuardExtension.entitlements 配置正确 ✓

## 🚨 常见问题

### 问题 1: Extension 不启动但没有错误
**原因**：App Groups 不一致
**解决**：统一使用 group.com.morphvpn.app.wireguard

### 问题 2: "VPN configuration is not allowed"
**原因**：Provisioning Profile 问题
**解决**：
1. 确保在真机上测试
2. 检查 Team 是否正确
3. 重新生成 Provisioning Profile

### 问题 3: Extension 启动但立即崩溃
**原因**：缺少 Frameworks
**解决**：确保 WireGuardKit 和 libwg-go.a 已链接

## ✅ 成功标志

当一切正常时：

### Xcode Console
```
🎯 PacketTunnelProvider: init() called
🚀 PacketTunnelProvider: startTunnel() called
✅ Got WireGuard config, length: 316 bytes
✅ Successfully parsed WireGuard configuration
✅ WireGuard tunnel started successfully!
📡 WireGuardPlugin: VPN status changed to: connected
```

### iOS 设备
- ✅ 状态栏显示 VPN 图标
- ✅ 设置 → 通用 → VPN 显示 "已连接"

### React UI
- ✅ 状态显示 "connected"
- ✅ 按钮变为 "Disconnect WireGuard"

## 📞 需要帮助？

如果问题仍然存在，请提供：

1. **完整的 Xcode Console 日志**
2. **Console.app 的日志**（搜索 PacketTunnelProvider）
3. **Xcode 截图**：
   - Scheme 配置
   - App target 的 Signing & Capabilities
   - WireGuardExtension target 的 Signing & Capabilities
   - WireGuardExtension target 的 General → Frameworks
4. **确认**：
   - 是否在真机上测试
   - iOS 版本
   - Xcode 版本

## 🎉 总结

**最可能的问题**：App Groups 配置不一致

**修复方案**：
1. 统一 App Groups 为 `group.com.morphvpn.app.wireguard`
2. 在 Xcode 中验证所有配置
3. 清理并重新构建
4. 在真机上测试

**关键点**：
- 必须在真机上测试
- 必须看到 PacketTunnelProvider 的日志
- App Groups 必须一致
