# WireGuardKit 集成指南

## ✅ 已完成的准备工作

1. ✅ Podfile 已更新（添加了 WireGuardKit 依赖）
2. ✅ PacketTunnelProvider 实现已创建
3. ✅ Entitlements 已配置（App Groups）

## 🚀 集成步骤

### 步骤 1: 安装 CocoaPods 依赖

在项目根目录运行：

```bash
bash INSTALL_WIREGUARDKIT.sh
```

或者手动安装：

```bash
cd ios/App
rm -rf Pods Podfile.lock
pod repo update
pod install
cd ../..
```

**预期输出**：
```
Analyzing dependencies
Fetching podspec for `WireGuardKit`
Downloading WireGuardKit
Installing WireGuardKit
```

**注意**：首次安装可能需要几分钟，因为需要下载和编译 WireGuardKit。

### 步骤 2: 在 Xcode 中替换 PacketTunnelProvider

1. **打开 Xcode**：
   ```bash
   npx cap open ios
   ```

2. **找到文件**：
   - 在左侧导航栏，展开 `WireGuardExtension` 文件夹
   - 找到 `PacketTunnelProvider.swift`

3. **替换内容**：
   - 打开项目根目录的 `PacketTunnelProvider_WireGuardKit.swift`
   - 复制全部内容
   - 粘贴到 Xcode 中的 `PacketTunnelProvider.swift`，替换原有内容
   - 保存（⌘S）

### 步骤 3: 配置 Entitlements

#### 3.1 主 App 的 Entitlements

1. 在 Xcode 中，选择 **App** target
2. 选择 **Signing & Capabilities** 标签
3. 添加 **App Groups** capability（如果还没有）
4. 点击 **+** 添加 group：`group.com.morphvpn.app`
5. 确保勾选这个 group

#### 3.2 Extension 的 Entitlements

1. 选择 **WireGuardExtension** target
2. 选择 **Signing & Capabilities** 标签
3. 添加 **App Groups** capability（如果还没有）
4. 添加相同的 group：`group.com.morphvpn.app`
5. 确保勾选这个 group

或者直接使用提供的 entitlements 文件：

1. 在 Xcode 中找到 `WireGuardExtension.entitlements`
2. 打开项目根目录的 `WireGuardExtension.entitlements`
3. 复制内容并粘贴到 Xcode 中的文件
4. 保存

### 步骤 4: 构建和运行

1. **清理构建**：
   - 菜单栏 → **Product** → **Clean Build Folder** (⇧⌘K)

2. **构建项目**：
   - 选择 **App** scheme
   - 选择你的 iOS 设备
   - 点击 **Build** (⌘B)

3. **运行到设备**：
   - 点击 **Run** (⌘R)
   - 等待应用安装并启动

## ✅ 测试 VPN 连接

### 1. 在应用中测试

1. 进入登录页面
2. 点击 **"Test WireGuard"** 按钮
3. 首次运行会弹出 VPN 权限请求，点击 **Allow**
4. 等待连接

### 2. 查看连接状态

**在应用中**：
- 调试信息面板应显示 "平台: ios"
- 状态应该从 "connecting" 变为 "connected"

**在 iPhone 设置中**：
- Settings → General → VPN & Device Management
- 应该看到 **TestVPN** 配置
- 状态应该是 **Connected**

**在 Xcode 控制台**：
应该看到类似的日志：
```
✅ WireGuardPlugin: Plugin loaded successfully
🔵 WireGuardPlugin: connect() called
🟢 WireGuard: Starting tunnel
📝 WireGuard: Parsing configuration
✅ WireGuard: Configuration parsed successfully
   Interface: 10.8.0.2/24
   Peers: 1
✅ WireGuard: Tunnel started successfully
```

### 3. 验证 VPN 流量

**测试方法 1：检查 IP 地址**

在浏览器中访问：https://ifconfig.me

应该显示 VPN 服务器的 IP 地址（65.20.89.15）

**测试方法 2：查看网络流量**

在 Xcode 控制台中，应该看到 WireGuard 的日志输出。

## 🔍 故障排查

### 问题 1: pod install 失败

**错误**：`CocoaPods could not find compatible versions for pod "WireGuardKit"`

**原因**：WireGuardKit 不在 CocoaPods 官方仓库，需要从 GitHub 引用。

**解决**：
```bash
bash INSTALL_WIREGUARDKIT.sh
```

或者手动：
```bash
cd ios/App
rm -rf Pods Podfile.lock
pod repo update
pod install
cd ../..
```

**注意**：Podfile 已配置为从 GitHub 获取 WireGuardKit：
```ruby
pod 'WireGuardKit', :git => 'https://github.com/passepartoutvpn/wireguard-apple.git', :tag => '1.1.3'
```

### 问题 2: 编译错误 - "No such module 'WireGuardKit'"

**解决**：
1. 确保 `pod install` 成功完成
2. 在 Xcode 中，关闭项目
3. 打开 `App.xcworkspace`（不是 .xcodeproj）
4. Clean Build Folder (⇧⌘K)
5. 重新构建

### 问题 3: 连接失败 - "Failed to parse configuration"

**检查**：
1. 确保 WireGuard 配置格式正确
2. 查看 Xcode 控制台的详细错误信息
3. 验证配置中的密钥格式

### 问题 4: 连接成功但无法访问网络

**可能原因**：
1. WireGuard 服务器配置问题
2. 防火墙阻止
3. 路由配置问题

**检查**：
1. 确认服务器 IP 和端口正确：`65.20.89.15:51820`
2. 确认密钥正确
3. 查看 Xcode 控制台的 WireGuard 日志

### 问题 5: Extension 崩溃

**解决**：
1. 查看 Xcode 控制台的崩溃日志
2. 确保 entitlements 配置正确
3. 确保 App Groups 在两个 target 中都配置了

## 📊 功能验证清单

- [ ] CocoaPods 依赖安装成功
- [ ] PacketTunnelProvider 代码已替换
- [ ] App Groups 已配置
- [ ] 应用可以构建成功
- [ ] VPN 权限请求正常
- [ ] 可以创建 VPN 配置
- [ ] 连接状态显示正确
- [ ] Xcode 日志显示 WireGuard 启动
- [ ] IP 地址显示为 VPN 服务器 IP
- [ ] 可以正常访问网络

## 🎉 成功标志

当你看到以下内容时，说明集成成功：

1. **Xcode 控制台**：
   ```
   ✅ WireGuard: Tunnel started successfully
   ```

2. **iPhone 设置**：
   - VPN 状态显示 "Connected"
   - 不再显示 "Update Required"

3. **网络测试**：
   - 访问 https://ifconfig.me 显示 VPN 服务器 IP
   - 可以正常浏览网页

## 📝 配置说明

### 当前 WireGuard 配置

```
Endpoint: 65.20.89.15:51820
Interface Address: 10.8.0.2/24
DNS: 1.1.1.1
```

### 修改配置

如果需要修改配置，编辑 `src/components/TestVpn.tsx` 中的 `myConfig` 变量。

## 🔐 安全提示

1. **不要提交私钥到 Git**
2. **使用环境变量存储敏感配置**
3. **定期更换密钥**
4. **使用强密码保护设备**

## 📚 参考资源

- [WireGuardKit GitHub](https://github.com/passepartoutvpn/wireguard-apple)
- [WireGuard 官方文档](https://www.wireguard.com/)
- [Apple Network Extension 文档](https://developer.apple.com/documentation/networkextension)

---

**准备好了吗？** 运行 `cd ios/App && pod install` 开始集成！
