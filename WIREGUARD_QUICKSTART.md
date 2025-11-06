# WireGuard插件快速入门

## 5分钟快速集成指南

### 步骤1: 在Xcode中打开项目

```bash
cd ios/App
open App.xcworkspace
```

### 步骤2: 添加Network Extension Target

1. 在Xcode中: **File → New → Target**
2. 选择 **Network Extension**
3. 配置:
   - Product Name: `WireGuardExtension`
   - Bundle Identifier: `com.example.app.WireGuardExtension`
   - Language: Swift
   - 取消勾选 "Include UI Extension"

### 步骤3: 添加WireGuardKit

#### 使用Swift Package Manager:

1. **File → Add Packages**
2. 输入: `https://github.com/passepartoutvpn/wireguard-apple`
3. 选择最新版本
4. 添加到 **WireGuardExtension** target

### 步骤4: 配置Capabilities

#### 主App (App target):
1. 选择 **App** target
2. **Signing & Capabilities** → **+ Capability**
3. 添加:
   - Network Extensions
   - Personal VPN
   - App Groups (创建: `group.com.example.app.wireguard`)

#### Network Extension:
1. 选择 **WireGuardExtension** target
2. 添加相同的三个Capabilities
3. 使用相同的App Group

### 步骤5: 创建PacketTunnelProvider

在 `WireGuardExtension` 文件夹中创建 `PacketTunnelProvider.swift`:

```swift
import NetworkExtension
import WireGuardKit

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    private var adapter: WireGuardAdapter?
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        guard let protocolConfiguration = self.protocolConfiguration as? NETunnelProviderProtocol,
              let providerConfiguration = protocolConfiguration.providerConfiguration,
              let configString = providerConfiguration["wg_config"] as? String,
              let tunnelConfiguration = try? TunnelConfiguration(fromWgQuickConfig: configString) else {
            completionHandler(NSError(domain: "WireGuard", code: 1))
            return
        }
        
        adapter = WireGuardAdapter(with: self) { logLevel, message in
            print("WireGuard [\(logLevel)]: \(message)")
        }
        
        adapter?.start(tunnelConfiguration: tunnelConfiguration) { error in
            completionHandler(error)
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        adapter?.stop { _ in
            self.adapter = nil
            completionHandler()
        }
    }
}
```

### 步骤6: 更新Bundle ID

在 `ios/App/App/Plugins/WireGuardPlugin.swift` 中，找到第155行:

```swift
providerProtocol.providerBundleIdentifier = "com.example.app.WireGuardExtension"
```

替换为你的实际Bundle ID。

### 步骤7: 在代码中使用

```typescript
import WireGuard from './plugins/wireguard';

// 连接VPN
const config = `[Interface]
PrivateKey = YOUR_KEY
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = SERVER_KEY
Endpoint = vpn.example.com:51820
AllowedIPs = 0.0.0.0/0`;

await WireGuard.connect({ config, tunnelName: 'MyVPN' });
```

### 步骤8: 测试

1. 连接真机（不支持模拟器）
2. 在Xcode中点击 **Run**
3. 授权VPN权限
4. 测试连接

## 常见错误快速修复

### ❌ "VPN configuration is not allowed"
✅ 确保在真机上运行，检查Capabilities配置

### ❌ "Failed to start VPN"
✅ 检查Bundle ID是否正确，验证WireGuard配置格式

### ❌ 编译错误
✅ 确认WireGuardKit已添加到WireGuardExtension target

## 下一步

- 阅读完整文档: `WIREGUARD_PLUGIN_README.md`
- 查看详细设置: `ios/WIREGUARD_SETUP.md`
- 查看示例组件: `src/components/WireGuardExample.tsx`

## 需要帮助?

1. 检查Xcode控制台的错误信息
2. 查看故障排除部分
3. 提交Issue到项目仓库
