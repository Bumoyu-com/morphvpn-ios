# ✅ Podfile 已修复

## 🔴 问题

```
CocoaPods could not find compatible versions for pod "WireGuardKit"
```

## 🎯 原因

WireGuardKit **不在 CocoaPods 官方仓库**中，需要从 GitHub 直接引用。

## ✅ 解决方案

### 已修复的 Podfile

**文件**：`ios/App/Podfile`

```ruby
# WireGuard Extension Target
target 'WireGuardExtension' do
  platform :ios, '14.0'
  use_frameworks!
  
  # WireGuardKit from GitHub (official WireGuard implementation)
  pod 'WireGuardKit', :git => 'https://github.com/passepartoutvpn/wireguard-apple.git', :tag => '1.1.3'
end
```

### 关键变化

**之前（错误）**：
```ruby
pod 'WireGuardKit', '~> 1.0'  # ❌ 在 CocoaPods 仓库中找不到
```

**现在（正确）**：
```ruby
pod 'WireGuardKit', :git => 'https://github.com/passepartoutvpn/wireguard-apple.git', :tag => '1.1.3'  # ✅ 从 GitHub 获取
```

## 🚀 现在请执行

### 方法 1: 使用安装脚本（推荐）

```bash
bash INSTALL_WIREGUARDKIT.sh
```

这会自动：
1. 清理旧的 Pods
2. 更新 CocoaPods 仓库
3. 从 GitHub 安装 WireGuardKit

### 方法 2: 手动安装

```bash
cd ios/App
rm -rf Pods Podfile.lock
pod repo update
pod install
cd ../..
```

## ✅ 预期输出

```
Analyzing dependencies
Downloading dependencies
Cloning spec repo `trunk` from https://github.com/CocoaPods/Specs.git
Cloning https://github.com/passepartoutvpn/wireguard-apple.git
Installing WireGuardKit (1.1.3)
Generating Pods project
Integrating client project

[!] Please close any current Xcode sessions and use `App.xcworkspace` for this project from now on.
Pod installation complete! There are X dependencies from the Podfile and Y total pods installed.
```

## ⏱️ 安装时间

**首次安装**：3-5 分钟
- 需要从 GitHub 克隆 WireGuardKit 仓库
- 需要编译 WireGuard 的 C 代码

**后续安装**：30 秒 - 1 分钟
- 使用缓存的代码

## 🔍 验证安装

### 检查 Pods 目录

```bash
ls ios/App/Pods/WireGuardKit
```

应该看到：
```
Sources/
WireGuardKit.xcodeproj
...
```

### 检查 Podfile.lock

```bash
cat ios/App/Podfile.lock | grep WireGuardKit
```

应该看到：
```
- WireGuardKit (1.1.3):
```

## 📝 重要提示

### 1. 必须打开 .xcworkspace

安装完成后，**必须**打开 `App.xcworkspace`，不是 `.xcodeproj`：

```bash
npx cap open ios  # 这会自动打开 .xcworkspace
```

或者在 Xcode 中：
```
File → Open → 选择 ios/App/App.xcworkspace
```

### 2. 网络要求

安装需要访问 GitHub，确保：
- ✅ 网络连接正常
- ✅ 可以访问 GitHub
- ✅ 没有防火墙阻止

### 3. Xcode 版本

确保 Xcode 版本 ≥ 13.0

## 🔧 故障排查

### 问题 1: 克隆失败

**错误**：`fatal: unable to access 'https://github.com/passepartoutvpn/wireguard-apple.git/'`

**解决**：
1. 检查网络连接
2. 尝试手动克隆测试：
   ```bash
   git clone https://github.com/passepartoutvpn/wireguard-apple.git /tmp/test
   ```
3. 如果失败，可能是网络问题或 GitHub 访问受限

### 问题 2: 编译错误

**错误**：编译 WireGuardKit 时出错

**解决**：
1. 确保 Xcode Command Line Tools 已安装：
   ```bash
   xcode-select --install
   ```
2. 清理并重试：
   ```bash
   bash INSTALL_WIREGUARDKIT.sh
   ```

### 问题 3: 版本冲突

**错误**：依赖版本冲突

**解决**：
```bash
cd ios/App
rm -rf Pods Podfile.lock ~/Library/Caches/CocoaPods
pod install
cd ../..
```

## 📚 下一步

安装成功后：

1. **打开 Xcode**：
   ```bash
   npx cap open ios
   ```

2. **替换 PacketTunnelProvider**：
   - 使用 `PacketTunnelProvider_WireGuardKit.swift` 的内容

3. **配置 App Groups**：
   - 在两个 target 中添加 `group.com.morphvpn.app`

4. **构建和运行**：
   - Clean Build Folder (⇧⌘K)
   - Run (⌘R)

详细步骤参考：`INTEGRATION_COMPLETE.md`

---

**准备好了吗？** 运行 `bash INSTALL_WIREGUARDKIT.sh` 开始安装！
