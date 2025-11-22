# WireGuardKit 集成指南 - Swift Package Manager

## ✅ 正确的集成方式

根据官方文档，WireGuardKit 应该通过 **Swift Package Manager (SPM)** 集成，而不是 CocoaPods。

## 🚀 集成步骤

### 步骤 1: 在 Xcode 中添加 Swift Package

1. **打开 Xcode 项目**：
   ```bash
   npx cap open ios
   ```

2. **添加 Swift Package**：
   - 在 Xcode 中，选择项目（蓝色图标）
   - 选择项目（不是 target）
   - 切换到 **Package Dependencies** 标签
   - 点击 **"+"** 按钮

3. **输入 Package URL**：
   ```
   https://git.zx2c4.com/wireguard-apple
   ```
   
   或者使用 GitHub 镜像：
   ```
   https://github.com/WireGuard/wireguard-apple
   ```

4. **选择版本**：
   - Dependency Rule: **Up to Next Major Version**
   - Version: **1.0.0** (或最新版本)
   - 点击 **Add Package**

5. **选择 Target**：
   - 勾选 **WireGuardKit**
   - 在 "Add to Target" 中选择：
     - ✅ **WireGuardExtension** (Network Extension target)
     - ✅ **App** (主应用 target)
   - 点击 **Add Package**

### 步骤 2: 创建 WireGuardGoBridge 构建目标

WireGuardKit 依赖 `wireguard-go-bridge` 库，需要手动创建构建目标。

#### 2.1 创建 iOS 构建目标

1. **创建新 Target**：
   - File → New → Target
   - 切换到 **Other** 标签
   - 选择 **External Build System**
   - 点击 **Next**

2. **配置 Target**：
   - **Product Name**: `WireGuardGoBridgeiOS`
   - **Build Tool**: `/usr/bin/make` (默认)
   - 点击 **Finish**

3. **配置 Info**：
   - 选择 `WireGuardGoBridgeiOS` target
   - 切换到 **Info** 标签
   - 在 **External Build Tool Configuration** 下：
     - **Directory**: 
       ```
       ${BUILD_DIR%Build/*}SourcePackages/checkouts/wireguard-apple/Sources/WireGuardKitGo
       ```

4. **配置 Build Settings**：
   - 切换到 **Build Settings** 标签
   - 搜索 `SDKROOT`
   - 设置值为：`iphoneos`

#### 2.2 创建 macOS 构建目标（如果需要）

如果你的应用也支持 macOS，重复上述步骤，但：
- **Product Name**: `WireGuardGoBridgemacOS`
- **SDKROOT**: `macosx`

### 步骤 3: 配置依赖关系

1. **选择 WireGuardExtension target**
2. **切换到 Build Phases 标签**
3. **在 Dependencies 部分**：
   - 点击 **"+"**
   - 添加 `WireGuardGoBridgeiOS`

4. **在 Link Binary With Libraries 部分**：
   - 确认 **WireGuardKit** 已添加
   - 如果没有，点击 **"+"** 添加

### 步骤 4: 配置主应用 Target

1. **选择 App target**
2. **切换到 Build Phases 标签**
3. **在 Link Binary With Libraries 部分**：
   - 确认 **WireGuardKit** 已添加

### 步骤 5: 禁用 Bitcode（仅 iOS）

1. **选择 App target**
2. **Build Settings** → 搜索 `Bitcode`
3. **Enable Bitcode**: 设置为 **No**

4. **对 WireGuardExtension target 重复相同操作**

### 步骤 6: 替换 PacketTunnelProvider 代码

1. **打开** `WireGuardExtension/PacketTunnelProvider.swift`
2. **复制** 项目根目录的 `PacketTunnelProvider_WireGuardKit.swift` 内容
3. **粘贴替换**
4. **保存** (⌘S)

### 步骤 7: 配置 App Groups

#### 在 App target：
1. **Signing & Capabilities** 标签
2. 点击 **+ Capability**
3. 添加 **App Groups**
4. 添加 group：`group.com.morphvpn.app`

#### 在 WireGuardExtension target：
1. **Signing & Capabilities** 标签
2. 添加 **App Groups**
3. 添加相同的 group：`group.com.morphvpn.app`

### 步骤 8: 构建和运行

1. **Clean Build Folder**: Product → Clean Build Folder (⇧⌘K)
2. **Build**: Product → Build (⌘B)
3. **Run**: Product → Run (⌘R) 到真实 iOS 设备

## ✅ 验证安装

### 检查 Package Dependencies

在 Xcode 项目导航器中，应该看到：
```
📦 Package Dependencies
  └── wireguard-apple
      └── WireGuardKit
```

### 检查 Build Phases

在 WireGuardExtension target 的 Build Phases 中：
- **Dependencies**: 包含 `WireGuardGoBridgeiOS`
- **Link Binary With Libraries**: 包含 `WireGuardKit`

### 检查构建日志

构建时应该看到：
```
Building WireGuardGoBridgeiOS
Compiling wireguard-go-bridge
```

## 🔍 故障排查

### 问题 1: 无法添加 Package

**错误**: "Couldn't communicate with a helper application"

**解决**:
1. 重启 Xcode
2. 清理 Derived Data：
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. 重试添加 Package

### 问题 2: WireGuardGoBridge 构建失败

**错误**: "No such file or directory"

**解决**:
1. 确认 Directory 路径正确：
   ```
   ${BUILD_DIR%Build/*}SourcePackages/checkouts/wireguard-apple/Sources/WireGuardKitGo
   ```
2. 确认 SDKROOT 设置正确（`iphoneos` 或 `macosx`）
3. Clean Build Folder 并重新构建

### 问题 3: 编译错误 "No such module 'WireGuardKit'"

**解决**:
1. 确认 WireGuardKit 已添加到 target 的 Link Binary With Libraries
2. 确认 Swift Package 已成功下载
3. 在 Xcode 中：File → Packages → Reset Package Caches
4. Clean Build Folder 并重新构建

### 问题 4: 运行时崩溃

**解决**:
1. 确认 App Groups 在两个 target 中都配置了
2. 确认 entitlements 文件正确
3. 查看 Xcode 控制台的详细错误信息

## 📝 重要提示

### 1. 不要使用 CocoaPods

WireGuardKit **不支持** CocoaPods，必须使用 Swift Package Manager。

### 2. 必须创建 WireGuardGoBridge Target

这是必需的步骤，因为 Swift Package Manager 无法自动构建 Go 代码。

### 3. 必须在真实设备上测试

VPN 功能不能在模拟器上运行。

### 4. 需要正确的签名

确保：
- 开发团队已选择
- Provisioning Profile 正确
- 包含 Network Extension 权限

## 📚 参考资源

- [官方仓库](https://github.com/WireGuard/wireguard-apple)
- [官方文档](https://git.zx2c4.com/wireguard-apple)
- [WireGuard 官网](https://www.wireguard.com/)

## 🎯 下一步

完成集成后：

1. **测试连接**：
   - 运行应用到设备
   - 点击 "Test WireGuard"
   - 允许 VPN 权限
   - 查看 Xcode 控制台日志

2. **验证 VPN**：
   - 访问 https://ifconfig.me
   - 应该显示 VPN 服务器 IP

3. **查看统计**：
   - 在应用中查看连接状态
   - 查看流量统计

---

**准备好了吗？** 打开 Xcode 开始集成！
