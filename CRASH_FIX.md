# Extension 崩溃问题修复

## 🔍 问题分析（基于 Console.app 日志）

### 发现的问题

✅ **Extension 成功启动**：
```
🎯 PacketTunnelProvider: init() called
🚀 PacketTunnelProvider: startTunnel() called
📦 Getting protocol configuration...
✅ Got protocol configuration
✅ Got WireGuard config, length: 316 bytes
📄 Config content: [配置正确]
🔧 Parsing WireGuard configuration...
```

❌ **在解析配置时崩溃**：
```
WireGuardExtension[14449] Corpse allowed 1 of 5
Connection to plugin interrupted while in use.
Extension com.morphvpn.app.WireGuardExtension died unexpectedly
Formulating fatal 309 report for corpse[14449] WireGuardExtension
```

### 崩溃原因

**问题**：`TunnelConfiguration(fromWgQuickConfig:)` 调用时崩溃

**可能的原因**：
1. ❌ libwg-go.a 没有正确链接到 WireGuardExtension target
2. ❌ WireGuardKit 版本与 libwg-go.a 不兼容
3. ❌ 使用了远程 WireGuardKit 但需要本地构建的 Go bridge

## 🔧 解决方案

### 方案 1: 确保 libwg-go.a 正确链接（推荐）

#### 步骤 1: 在 Xcode 中检查

```
1. 打开 Xcode: npx cap open ios

2. 选择 WireGuardExtension target
   → General
   → Frameworks and Libraries
   → 确认包含：
      ✓ WireGuardKit (from Swift Package)
      ✓ NetworkExtension.framework
      ✓ libwg-go.a

3. 如果 libwg-go.a 不在列表中：
   → 点击 + 按钮
   → Add Other... → Add Files...
   → 选择 ios/App/libwg-go.a
   → 确保 "Embed" 设置为 "Do Not Embed"
```

#### 步骤 2: 检查 Build Phases

```
选择 WireGuardExtension target
→ Build Phases
→ Link Binary With Libraries
→ 确认包含：
   ✓ libwg-go.a
   ✓ NetworkExtension.framework
```

#### 步骤 3: 检查 Build Settings

```
选择 WireGuardExtension target
→ Build Settings
→ 搜索 "Library Search Paths"
→ 确认包含：$(PROJECT_DIR)/../..
```

### 方案 2: 使用非官方修复版 WireGuardKit

根据 Xcode 16 的指南，官方 WireGuardKit 可能有兼容性问题。

#### 步骤 1: 移除当前的 WireGuardKit

```
1. 在 Xcode 中
2. Project Navigator → Package Dependencies
3. 右键点击 wireguard-apple
4. Remove Package Reference
```

#### 步骤 2: 添加非官方修复版

```
1. File → Add Package Dependencies
2. 输入 URL: https://github.com/ut360e/wireguard-apple.git
3. Dependency Rule: Branch → main
4. Add Package
5. 选择 WireGuardKit
6. 添加到 WireGuardExtension target
```

### 方案 3: 简化 PacketTunnelProvider（临时方案）

如果上述方案都不行，可以先简化代码来定位问题。

#### 修改 PacketTunnelProvider.swift

在解析配置前添加更多保护：

```swift
// 解析配置
NSLog("🔧 Parsing WireGuard configuration...")
let tunnelConfiguration: TunnelConfiguration
do {
    // 添加保护：确保配置不为空
    guard !configString.isEmpty else {
        throw NSError(domain: "WireGuard", code: 5, userInfo: [
            NSLocalizedDescriptionKey: "Config string is empty"
        ])
    }
    
    // 添加保护：检查配置格式
    guard configString.contains("[Interface]") && configString.contains("[Peer]") else {
        throw NSError(domain: "WireGuard", code: 6, userInfo: [
            NSLocalizedDescriptionKey: "Invalid config format"
        ])
    }
    
    NSLog("🔍 Config validation passed, attempting to parse...")
    
    // 使用 try? 先测试是否能解析
    if let testConfig = try? TunnelConfiguration(fromWgQuickConfig: configString) {
        tunnelConfiguration = testConfig
        NSLog("✅ Successfully parsed WireGuard configuration")
    } else {
        NSLog("❌ TunnelConfiguration init returned nil")
        throw NSError(domain: "WireGuard", code: 7, userInfo: [
            NSLocalizedDescriptionKey: "Failed to parse config"
        ])
    }
    
    NSLog("📍 Interface addresses: \(tunnelConfiguration.interface.addresses.map { $0.stringRepresentation }.joined(separator: ", "))")
    NSLog("👥 Peers count: \(tunnelConfiguration.peers.count)")
} catch {
    NSLog("❌ Failed to parse WireGuard config: \(error.localizedDescription)")
    NSLog("❌ Error details: \(error)")
    let nsError = NSError(domain: "WireGuard", code: 4, userInfo: [
        NSLocalizedDescriptionKey: "Invalid WireGuard configuration: \(error.localizedDescription)"
    ])
    completionHandler(nsError)
    return
}
```

## 🎯 推荐的修复步骤

### 步骤 1: 检查 libwg-go.a 链接

这是最可能的问题。

```bash
# 打开 Xcode
npx cap open ios

# 按照"方案 1"的步骤检查
```

### 步骤 2: 如果步骤 1 无效，切换到非官方 WireGuardKit

```bash
# 按照"方案 2"的步骤操作
```

### 步骤 3: 清理并重新构建

```
Product → Clean Build Folder (⇧⌘K)
Product → Build (⌘B)
Product → Run (⌘R)
```

### 步骤 4: 查看日志

在 Console.app 中应该看到：

**如果修复成功**：
```
🔧 Parsing WireGuard configuration...
✅ Successfully parsed WireGuard configuration
📍 Interface addresses: 10.8.0.2/24
👥 Peers count: 1
🔨 Creating WireGuard adapter...
✅ WireGuard adapter created
🚀 Starting WireGuard adapter...
✅ WireGuard tunnel started successfully!
```

**如果仍然崩溃**：
```
🔧 Parsing WireGuard configuration...
WireGuardExtension[xxxx] Corpse allowed 1 of 5
Extension died unexpectedly
```

## 📊 诊断流程

```
Extension 启动 ✅
    ↓
获取配置 ✅
    ↓
开始解析配置
    ↓
    ├─→ 成功解析 ✅
    │       ↓
    │   创建 WireGuard 适配器
    │       ↓
    │   启动隧道
    │
    └─→ 解析时崩溃 ❌ (当前问题)
            ↓
        检查：
        1. libwg-go.a 是否链接
        2. WireGuardKit 版本
        3. Build Settings
```

## 🚨 关键检查点

### 在 Xcode 中必须确认：

1. **WireGuardExtension target → General → Frameworks**
   - [ ] WireGuardKit ✓
   - [ ] NetworkExtension.framework ✓
   - [ ] libwg-go.a ✓ (最重要！)

2. **WireGuardExtension target → Build Phases → Link Binary**
   - [ ] libwg-go.a ✓
   - [ ] NetworkExtension.framework ✓

3. **WireGuardExtension target → Build Settings**
   - [ ] Library Search Paths 包含 libwg-go.a 的路径 ✓

## 📝 验证修复

### 修复前的日志：
```
🔧 Parsing WireGuard configuration...
WireGuardExtension[14449] Corpse allowed 1 of 5
Extension died unexpectedly
```

### 修复后的日志：
```
🔧 Parsing WireGuard configuration...
✅ Successfully parsed WireGuard configuration
📍 Interface addresses: 10.8.0.2/24
👥 Peers count: 1
🔨 Creating WireGuard adapter...
✅ WireGuard adapter created
🚀 Starting WireGuard adapter...
✅ WireGuard tunnel started successfully!
```

## 💡 为什么会崩溃？

`TunnelConfiguration(fromWgQuickConfig:)` 内部需要调用 Go 代码（通过 libwg-go.a）来解析配置。

如果 libwg-go.a 没有正确链接：
- Swift 代码可以编译通过
- 但运行时调用 Go 函数会崩溃
- 系统会生成 "Corpse" 崩溃报告

## ✅ 总结

**问题**：Extension 在解析 WireGuard 配置时崩溃

**原因**：libwg-go.a 可能没有正确链接到 WireGuardExtension target

**解决**：
1. 在 Xcode 中确保 libwg-go.a 已添加到 WireGuardExtension target
2. 检查 Build Phases → Link Binary With Libraries
3. 如果问题仍然存在，切换到非官方 WireGuardKit

**验证**：在 Console.app 中看到 "Successfully parsed WireGuard configuration"

## 📞 需要帮助？

如果问题仍然存在，请提供：

1. **Xcode 截图**：
   - WireGuardExtension target → General → Frameworks
   - WireGuardExtension target → Build Phases → Link Binary
   - WireGuardExtension target → Build Settings → Library Search Paths

2. **Console.app 日志**：
   - 从 "startTunnel() called" 到崩溃的完整日志

3. **确认**：
   - libwg-go.a 文件大小（应该是 3.0M）
   - WireGuardKit 来源（官方 or 非官方）
   - Xcode 版本
