# WireGuard iOS Plugin Setup Guide

## 概述
此插件使用iOS的NetworkExtension框架实现WireGuard VPN功能。需要创建一个Network Extension目标来处理实际的VPN连接。

## 前置要求

1. **Apple Developer账号**：需要付费的开发者账号
2. **Network Extension权限**：需要在Apple Developer Portal中启用
3. **WireGuardKit**：Apple官方的WireGuard实现库

## 设置步骤

### 1. 在Xcode中添加Network Extension Target

1. 打开 `ios/App/App.xcworkspace`
2. 选择 File → New → Target
3. 选择 "Network Extension"
4. 配置：
   - Product Name: `WireGuardExtension`
   - Bundle Identifier: `com.example.app.WireGuardExtension`
   - 确保 "Include UI Extension" 未选中

### 2. 添加WireGuardKit依赖

#### 方法1: 使用Swift Package Manager (推荐)

1. 在Xcode中，选择 File → Add Packages
2. 输入URL: `https://github.com/passepartoutvpn/wireguard-apple`
3. 选择版本并添加到 `WireGuardExtension` target

#### 方法2: 使用CocoaPods

在 `ios/App/Podfile` 中添加:

```ruby
target 'WireGuardExtension' do
  pod 'WireGuardKit', '~> 1.0'
end
```

然后运行:
```bash
cd ios/App
pod install
```

### 3. 配置App Capabilities

#### 主App (App target):
1. 在Xcode中选择App target
2. 进入 "Signing & Capabilities"
3. 点击 "+ Capability"
4. 添加以下权限：
   - **Network Extensions**
   - **Personal VPN**
   - **App Groups** (创建: `group.com.example.app.wireguard`)

#### Network Extension (WireGuardExtension target):
1. 选择 WireGuardExtension target
2. 添加相同的权限：
   - **Network Extensions**
   - **Personal VPN**
   - **App Groups** (使用相同的: `group.com.example.app.wireguard`)

### 4. 更新Info.plist

#### 主App的Info.plist (`ios/App/App/Info.plist`):

添加以下内容:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

#### Network Extension的Info.plist:

确保包含:

```xml
<key>NEProviderClasses</key>
<dict>
    <key>com.apple.networkextension.packet-tunnel</key>
    <string>$(PRODUCT_MODULE_NAME).PacketTunnelProvider</string>
</dict>
```

### 5. 创建PacketTunnelProvider

在 `WireGuardExtension` 目录创建 `PacketTunnelProvider.swift`:

```swift
import NetworkExtension
import WireGuardKit

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    private var adapter: WireGuardAdapter?
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        // 从配置中获取WireGuard配置
        guard let protocolConfiguration = self.protocolConfiguration as? NETunnelProviderProtocol,
              let providerConfiguration = protocolConfiguration.providerConfiguration,
              let configString = providerConfiguration["wg_config"] as? String else {
            completionHandler(NSError(domain: "WireGuard", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing configuration"]))
            return
        }
        
        // 解析WireGuard配置
        guard let tunnelConfiguration = try? TunnelConfiguration(fromWgQuickConfig: configString) else {
            completionHandler(NSError(domain: "WireGuard", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid configuration"]))
            return
        }
        
        // 创建WireGuard适配器
        adapter = WireGuardAdapter(with: self) { logLevel, message in
            print("WireGuard [\(logLevel)]: \(message)")
        }
        
        // 启动隧道
        adapter?.start(tunnelConfiguration: tunnelConfiguration) { error in
            if let error = error {
                print("Failed to start WireGuard: \(error)")
                completionHandler(error)
            } else {
                print("WireGuard started successfully")
                completionHandler(nil)
            }
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        adapter?.stop { error in
            if let error = error {
                print("Failed to stop WireGuard: \(error)")
            }
            self.adapter = nil
            completionHandler()
        }
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // 处理来自主App的消息（可选）
        completionHandler?(nil)
    }
}
```

### 6. 更新WireGuardPlugin.swift中的Bundle ID

在 `ios/App/App/Plugins/WireGuardPlugin.swift` 中，找到这一行:

```swift
providerProtocol.providerBundleIdentifier = "com.example.app.WireGuardExtension"
```

替换为你的实际Bundle ID。

### 7. 配置Provisioning Profiles

1. 登录 [Apple Developer Portal](https://developer.apple.com)
2. 进入 Certificates, Identifiers & Profiles
3. 为主App和Network Extension分别创建App IDs
4. 为两个App IDs都启用以下权限：
   - Network Extensions
   - Personal VPN
   - App Groups
5. 创建对应的Provisioning Profiles

### 8. 构建和测试

1. 在Xcode中选择主App target
2. 选择真机设备（Network Extension不能在模拟器上运行）
3. 点击 Run

## 使用示例

### TypeScript/JavaScript代码:

```typescript
import WireGuard from './plugins/wireguard';

// WireGuard配置示例
const config = `
[Interface]
PrivateKey = YOUR_PRIVATE_KEY
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = vpn.example.com:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
`;

// 连接VPN
async function connectVPN() {
  try {
    const result = await WireGuard.connect({
      config: config,
      tunnelName: 'MyVPN'
    });
    console.log('Connected:', result);
  } catch (error) {
    console.error('Connection failed:', error);
  }
}

// 断开VPN
async function disconnectVPN() {
  try {
    await WireGuard.disconnect();
    console.log('Disconnected');
  } catch (error) {
    console.error('Disconnect failed:', error);
  }
}

// 获取状态
async function getStatus() {
  const status = await WireGuard.getStatus();
  console.log('Status:', status);
}

// 监听状态变化
WireGuard.addListener('statusChanged', (data) => {
  console.log('VPN status changed:', data.status);
});
```

## 常见问题

### 1. "VPN configuration is not allowed"
- 确保在真机上测试
- 检查Provisioning Profile是否正确配置
- 确认App Groups配置一致

### 2. "Failed to start VPN"
- 检查WireGuard配置格式是否正确
- 确认Network Extension的Bundle ID正确
- 查看Xcode控制台的详细错误信息

### 3. 无法连接到服务器
- 检查服务器地址和端口是否正确
- 确认防火墙设置
- 验证密钥是否匹配

## 安全注意事项

1. **不要在代码中硬编码私钥**：使用安全存储（Keychain）
2. **验证配置来源**：确保配置来自可信源
3. **使用HTTPS**：如果从服务器获取配置，使用HTTPS
4. **定期更新密钥**：实施密钥轮换策略

## 参考资料

- [WireGuard官方文档](https://www.wireguard.com/)
- [Apple NetworkExtension文档](https://developer.apple.com/documentation/networkextension)
- [WireGuardKit GitHub](https://github.com/passepartoutvpn/wireguard-apple)
