# 修复 "plugin is not implemented on ios" 错误

## 问题分析

错误信息 `"Wireguard" plugin is not implemented on ios` 有以下几种可能原因：

### 1. ⚠️ **最可能的原因：在浏览器中运行，不是在 iOS 设备上**

如果你在浏览器中测试（通过 `npm run start` 或 `vite`），那么会使用 Web 版本的插件，它会返回 "not implemented" 错误。

**解决方案：必须在真实的 iOS 设备或 Xcode 模拟器中运行**

```bash
# 1. 构建项目
npm run build

# 2. 同步到 iOS
npx cap sync ios

# 3. 在 Mac 上打开 Xcode
npx cap open ios

# 4. 在 Xcode 中选择设备并运行
```

### 2. iOS 项目未正确编译插件文件

检查 Xcode 项目中是否包含插件文件：

1. 打开 `ios/App/App.xcodeproj`
2. 在左侧导航栏查找 `App/Plugins` 文件夹
3. 确认包含：
   - `WireGuardPlugin.swift`
   - `WireGuardPlugin.m`

如果文件不在项目中，需要手动添加：
- 右键点击 `App` 文件夹
- 选择 "Add Files to App..."
- 选择 `Plugins` 文件夹中的两个文件
- 确保勾选 "Copy items if needed" 和正确的 target

### 3. 插件未正确注册

检查 `WireGuardPlugin.m` 文件内容：

```objc
#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

// 插件名称必须是 "WireGuard"，与 TypeScript 中的名称一致
CAP_PLUGIN(WireGuardPlugin, "WireGuard",
    CAP_PLUGIN_METHOD(connect, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(disconnect, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(getStatus, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(saveConfig, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(deleteConfig, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(listTunnels, CAPPluginReturnPromise);
)
```

### 4. Swift 编译错误

在 Xcode 中构建项目时，检查是否有编译错误：

1. 打开 Xcode
2. 选择 Product → Build (⌘B)
3. 查看 Issue Navigator (⌘5) 中的错误

常见错误：
- `import Capacitor` 失败 → 需要运行 `pod install`
- `import NetworkExtension` 失败 → 需要添加 NetworkExtension.framework

### 5. 缺少必要的权限配置

确保以下文件配置正确：

#### `App.entitlements`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.networking.networkextension</key>
    <array>
        <string>packet-tunnel-provider</string>
    </array>
</dict>
</plist>
```

#### `Info.plist`
```xml
<key>NSLocalNetworkUsageDescription</key>
<string>需要访问本地网络以建立 VPN 连接</string>
```

## 调试步骤

### 步骤 1: 确认运行平台

在登录页面，查看调试信息：
- 如果显示 "平台: web" → 你在浏览器中运行，插件不会工作
- 如果显示 "平台: ios" → 继续下一步

### 步骤 2: 查看详细调试信息

页面底部会显示绿色的调试信息框，包含：
- 当前平台
- 是否为原生平台
- 插件模块是否加载
- 插件调用结果

### 步骤 3: 在 Xcode 中查看日志

1. 在 Xcode 中运行应用
2. 打开 Debug Area (⌘⇧Y)
3. 查看控制台输出
4. 搜索 "WireGuard" 或 "plugin" 相关日志

### 步骤 4: 验证插件注册

在 Swift 代码中添加日志：

```swift
override public func load() {
    print("✅ WireGuardPlugin loaded successfully")
    loadVPNManager()
    setupStatusObserver()
}
```

如果看到这条日志，说明插件已正确加载。

## 完整的测试流程

```bash
# 1. 清理并重新构建
rm -rf dist
npm run build

# 2. 同步到 iOS
npx cap sync ios

# 3. 在 Mac 上打开 Xcode
npx cap open ios

# 4. 在 Xcode 中：
#    - 选择真实设备或模拟器
#    - 点击 Run (⌘R)
#    - 等待应用启动
#    - 查看调试信息

# 5. 在应用中：
#    - 进入登录页面
#    - 查看平台信息（应该显示 "ios"）
#    - 点击 "Test WireGuard" 按钮
#    - 查看错误信息
```

## 常见错误和解决方案

### 错误: "plugin is not implemented on ios"
- **原因**: 在浏览器中运行
- **解决**: 在 iOS 设备上运行

### 错误: "VPN manager not initialized"
- **原因**: Network Extension target 未创建
- **解决**: 参考 `WIREGUARD_SETUP_INSTRUCTIONS.md` 创建 Network Extension

### 错误: "Failed to save VPN configuration"
- **原因**: 缺少权限或 entitlements 配置错误
- **解决**: 检查 App.entitlements 和 Info.plist

### 错误: "providerBundleIdentifier not found"
- **原因**: Network Extension target 的 Bundle ID 不匹配
- **解决**: 确保 Bundle ID 为 `com.morphvpn.app.WireGuardExtension`

## 当前项目状态

✅ 已完成：
- WireGuard 插件代码已添加
- 插件已注册到 Xcode 项目
- 权限配置已添加
- 调试工具已集成

⚠️ 待完成：
- 创建 Network Extension target（必须在 Xcode 中完成）
- 在真实 iOS 设备上测试

## 下一步

1. **在 Mac 上打开 Xcode**
2. **运行应用到真实设备**
3. **查看调试信息确认平台**
4. **如果仍然报错，查看 Xcode 控制台日志**

如果在 iOS 设备上仍然报错，请提供：
- Xcode 控制台的完整日志
- 调试信息框显示的内容
- 具体的错误信息
