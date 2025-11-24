# MorphVPN iOS - 完整设置指南

## 📋 目录

1. [快速开始](#快速开始)
2. [WireGuardKit 集成](#wireguardkit-集成)
3. [项目配置](#项目配置)
4. [构建和测试](#构建和测试)
5. [故障排查](#故障排查)
6. [API 使用](#api-使用)

---

## 🚀 快速开始

### 1. 安装插件

```bash
bash INSTALL_PLUGIN.sh
```

### 2. 打开 Xcode 项目

```bash
npx cap open ios
```

---

## ✅ WireGuardKit 集成

### ⚠️ 重要说明

WireGuardKit **必须通过 Swift Package Manager (SPM)** 集成，**不支持 CocoaPods**。

我们使用**本地 WireGuardKit 包**而不是远程包，以确保稳定性和可控性。

### 步骤 1: 下载 WireGuardKit

1. 从 [WireGuard Apple Releases](https://github.com/WireGuard/wireguard-apple/releases) 下载最新版本
2. 解压到项目根目录下的 `packages/wireguard-apple/` 文件夹

```bash
# 示例：下载并解压
cd /workspaces/morphvpn-ios
mkdir -p packages
cd packages
# 下载并解压 wireguard-apple 到此目录
# 最终路径应该是: packages/wireguard-apple/
```

### 步骤 2: 在 Xcode 中添加本地 Swift Package

1. 在 Xcode 中，选择项目根节点
2. 选择 **Package Dependencies** 标签
3. 点击 **"+"** 按钮
4. 选择 **"Add Local..."**
5. 导航到 `packages/wireguard-apple/` 文件夹并选择
6. 在弹出的对话框中：
   - 确保 **WireGuardKit** 被选中
   - 添加到 target：**WireGuardExtension**

### 步骤 3: 创建 WireGuardGoBridge Target

WireGuardKit 需要一个 Go 语言编译的桥接库。

1. File → New → Target
2. 选择 **Other** → **External Build System**
3. 配置：
   - **Product Name**: `WireGuardGoBridgeiOS`
   - **Build Tool**: `/usr/bin/make`

4. 选择新创建的 `WireGuardGoBridgeiOS` target
5. 进入 **Build Settings** 标签
6. 搜索并设置以下值：
   - **SDKROOT**: `iphoneos`
   
7. 进入 **Info** 标签
8. 设置 **Directory**:
   ```
   ${SRCROOT}/../../packages/wireguard-apple/Sources/WireGuardKitGo
   ```

### 步骤 4: 配置依赖关系

1. 选择 **WireGuardExtension** target
2. 进入 **Build Phases** 标签
3. 展开 **Dependencies** 部分
4. 点击 **"+"** 添加 `WireGuardGoBridgeiOS`
5. 展开 **Link Binary With Libraries** 部分
6. 确认 `WireGuardKit` 已添加（应该自动添加）

---

## 🔧 项目配置

### 配置 App Groups

App 和 Extension 需要共享数据，必须配置相同的 App Group。

#### 在 App target:
1. 选择 **App** target
2. 进入 **Signing & Capabilities** 标签
3. 点击 **"+ Capability"**
4. 添加 **App Groups**
5. 添加 group: `group.com.morphvpn.app`

#### 在 WireGuardExtension target:
1. 选择 **WireGuardExtension** target
2. 进入 **Signing & Capabilities** 标签
3. 点击 **"+ Capability"**
4. 添加 **App Groups**
5. 添加相同的 group: `group.com.morphvpn.app`

### 配置 Network Extension 权限

#### 在 App target:
1. 进入 **Signing & Capabilities** 标签
2. 添加以下 Capabilities:
   - **Network Extensions**
   - **Personal VPN**

#### 在 WireGuardExtension target:
1. 进入 **Signing & Capabilities** 标签
2. 添加以下 Capabilities:
   - **Network Extensions**
   - **Personal VPN**

### 禁用 Bitcode

WireGuardKit 不支持 Bitcode，需要在两个 target 中禁用。

#### 在 App 和 WireGuardExtension target:
1. 进入 **Build Settings** 标签
2. 搜索 "Bitcode"
3. 设置 **Enable Bitcode** 为 **No**

### 替换 PacketTunnelProvider 实现

1. 打开 `WireGuardExtension/PacketTunnelProvider.swift`
2. 复制根目录下 `PacketTunnelProvider_WireGuardKit.swift` 的内容
3. 粘贴替换原有内容
4. 保存文件

---

## 🏗️ 构建和测试

### 构建项目

1. 在 Xcode 中选择 **App** scheme
2. 选择真实 iOS 设备（Network Extension 不支持模拟器）
3. Clean Build Folder: **⇧⌘K**
4. Build: **⌘B**

### 运行测试

1. Run: **⌘R**
2. 在 App 中点击 "Test WireGuard" 按钮
3. 允许 VPN 权限提示
4. 查看 Xcode 控制台输出

### 验证连接

成功连接后应该看到：
```
✅ WireGuard: Tunnel started successfully
```

访问 https://ifconfig.me 应该显示 VPN 服务器的 IP 地址。

---

## 🐛 故障排查

### 问题 1: objectVersion = 70 导致 pod install 失败

**原因**: Xcode 16 使用了新的项目格式（objectVersion 70），但 CocoaPods 可能不完全支持。

**解决方案**: 
- objectVersion 70 是 Xcode 16 的标准格式，支持新的文件系统同步功能
- 如果 CocoaPods 报错，确保使用最新版本的 CocoaPods (1.15.0+)
- 或者考虑完全迁移到 SPM，移除 CocoaPods 依赖

```bash
# 更新 CocoaPods
sudo gem install cocoapods

# 清理并重新安装
cd ios/App
pod deintegrate
pod install
```

### 问题 2: Internal inconsistency error for WireGuardKitC

**原因**: WireGuardGoBridge target 的依赖配置问题或 Swift Package 路径不正确。

**解决方案**:
1. 确保 WireGuardKit 包路径正确指向本地 `packages/wireguard-apple/`
2. 确保 WireGuardGoBridgeiOS 的 Directory 设置正确
3. 清理并重新构建：
   ```
   Product → Clean Build Folder (⇧⌘K)
   File → Packages → Reset Package Caches
   ```

### 问题 3: unable to spawn process '/usr/bin/make'

**原因**: WireGuardGoBridgeiOS target 的构建路径配置不正确。

**解决方案**:
1. 检查 WireGuardGoBridgeiOS target 的 Info → Directory 设置
2. 确保路径指向本地包：
   ```
   ${SRCROOT}/../../packages/wireguard-apple/Sources/WireGuardKitGo
   ```
3. 确保该目录存在且包含 Makefile
4. 验证 make 命令可用：
   ```bash
   which make
   # 应该输出: /usr/bin/make
   ```

### 问题 4: 无法添加 Swift Package

**解决方案**:
```bash
# 清理 Xcode 缓存
rm -rf ~/Library/Developer/Xcode/DerivedData
# 重启 Xcode
```

### 问题 5: 编译错误 "No such module 'WireGuardKit'"

**解决方案**:
1. File → Packages → Reset Package Caches
2. Clean Build Folder (⇧⌘K)
3. 重新构建

### 问题 6: VPN 连接失败

**检查清单**:
- ✅ 在真实设备上测试（不是模拟器）
- ✅ App Groups 配置正确且一致
- ✅ Network Extension 权限已添加
- ✅ WireGuard 配置格式正确
- ✅ 服务器地址和端口可访问
- ✅ 密钥配置正确

---

## 📱 API 使用

### 连接 VPN

```typescript
import { WireGuard } from '@morphvpn/capacitor-wireguard';

const config = `[Interface]
PrivateKey = YOUR_PRIVATE_KEY
Address = 10.8.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = SERVER_PUBLIC_KEY
PresharedKey = PRESHARED_KEY
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
Endpoint = SERVER_IP:51820`;

async function connectVPN() {
  try {
    const result = await WireGuard.connect({
      config: config,
      tunnelName: 'MorphVPN'
    });
    console.log('✅ Connected:', result);
  } catch (error) {
    console.error('❌ Connection failed:', error);
  }
}
```

### 断开 VPN

```typescript
async function disconnectVPN() {
  try {
    await WireGuard.disconnect();
    console.log('✅ Disconnected');
  } catch (error) {
    console.error('❌ Disconnect failed:', error);
  }
}
```

### 获取状态

```typescript
async function getStatus() {
  const status = await WireGuard.getStatus();
  console.log('Status:', status.status);
  // 可能的值: 'connected', 'disconnected', 'connecting', 'disconnecting'
}
```

### 监听状态变化

```typescript
WireGuard.addListener('statusChanged', (data) => {
  console.log('VPN status changed:', data.status);
});
```

### 保存配置

```typescript
await WireGuard.saveConfig({
  config: config,
  tunnelName: 'MorphVPN'
});
```

### 删除配置

```typescript
await WireGuard.deleteConfig({
  tunnelName: 'MorphVPN'
});
```

### 列出所有隧道

```typescript
const result = await WireGuard.listTunnels();
console.log('Tunnels:', result.tunnels);
```

---

## 🎯 预期的项目结构

成功配置后，Xcode 项目应该包含：

```
📦 Package Dependencies
  └── wireguard-apple (Local)
      └── WireGuardKit

🎯 Targets
  ├── App
  ├── WireGuardExtension
  └── WireGuardGoBridgeiOS (External Build System)

📁 Project Structure
  ├── packages/
  │   └── wireguard-apple/          # 本地 WireGuardKit 包
  │       ├── Sources/
  │       │   ├── WireGuardKit/
  │       │   └── WireGuardKitGo/   # Go 桥接代码
  │       └── Package.swift
  └── ios/
      └── App/
          ├── App/                   # 主应用
          └── WireGuardExtension/    # Network Extension
```

---

## 📚 参考资料

- [WireGuard 官方文档](https://www.wireguard.com/)
- [WireGuard Apple GitHub](https://github.com/WireGuard/wireguard-apple)
- [Apple NetworkExtension 文档](https://developer.apple.com/documentation/networkextension)
- [Capacitor iOS 文档](https://capacitorjs.com/docs/ios)

---

## ⚠️ 安全注意事项

1. **不要在代码中硬编码私钥** - 使用 Keychain 存储
2. **验证配置来源** - 确保配置来自可信源
3. **使用 HTTPS** - 从服务器获取配置时使用加密连接
4. **定期更新密钥** - 实施密钥轮换策略
5. **最小权限原则** - 只请求必要的权限

---

**准备好了吗？** 按照上述步骤开始集成 WireGuardKit！

如有问题，请检查[故障排查](#故障排查)部分。
