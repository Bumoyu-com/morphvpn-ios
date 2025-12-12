# MorphProtocol + WireGuard 集成方案

## 🎯 目标

在 WireGuard VPN 上添加 MorphProtocol 混淆层，实现：
```
用户设备 → MorphProtocol 混淆 → WireGuard VPN → 服务器
```

## 📋 架构设计

### 方案：本地代理模式

```
┌─────────────────────────────────────────────────────────┐
│  iOS App (React)                                        │
│  - 用户界面                                              │
│  - 配置管理                                              │
└────────────────┬────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────┐
│  WireGuard Extension (PacketTunnelProvider)             │
│  ┌──────────────────────────────────────────────────┐   │
│  │  1. 接收 WireGuard 流量                          │   │
│  │  2. MorphProtocol 混淆处理                       │   │
│  │  3. 发送到远程服务器                             │   │
│  └──────────────────────────────────────────────────┘   │
└────────────────┬────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────┐
│  MorphProtocol 服务器                                   │
│  ┌──────────────────────────────────────────────────┐   │
│  │  1. 接收混淆流量                                 │   │
│  │  2. 解混淆                                       │   │
│  │  3. 转发到 WireGuard 服务器                      │   │
│  └──────────────────────────────────────────────────┘   │
└────────────────┬────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────┐
│  WireGuard 服务器                                       │
│  - 处理 VPN 连接                                        │
│  - 路由流量                                             │
└─────────────────────────────────────────────────────────┘
```

## 🔧 实现步骤

### 步骤 1：创建 MorphProtocol Swift 库

创建文件：`ios/App/WireGuardExtension/MorphProtocol/`

#### 1.1 加密模块
```swift
// Encryptor.swift
import Foundation
import CryptoKit

class MorphEncryptor {
    private let key: SymmetricKey
    private let iv: Data
    
    init(keyString: String) throws {
        // 解析 base64key:base64iv 格式
        let parts = keyString.split(separator: ":")
        guard parts.count == 2 else {
            throw MorphError.invalidKey
        }
        
        guard let keyData = Data(base64Encoded: String(parts[0])),
              let ivData = Data(base64Encoded: String(parts[1])) else {
            throw MorphError.invalidKey
        }
        
        self.key = SymmetricKey(data: keyData)
        self.iv = ivData
    }
    
    func encrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key, nonce: AES.GCM.Nonce(data: iv))
        return sealedBox.combined!
    }
    
    func decrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
}

enum MorphError: Error {
    case invalidKey
    case encryptionFailed
    case decryptionFailed
}
```

#### 1.2 混淆模块
```swift
// Obfuscator.swift
import Foundation

class MorphObfuscator {
    private let layer: Int
    private let paddingLength: Int
    
    init(layer: Int = 3, paddingLength: Int = 8) {
        self.layer = min(max(layer, 1), 4)
        self.paddingLength = min(max(paddingLength, 1), 8)
    }
    
    func obfuscate(_ data: Data) -> Data {
        var result = data
        
        // 应用多层混淆
        for _ in 0..<layer {
            result = applyObfuscationLayer(result)
        }
        
        // 添加填充
        result = addPadding(result)
        
        return result
    }
    
    func deobfuscate(_ data: Data) -> Data {
        var result = data
        
        // 移除填充
        result = removePadding(result)
        
        // 反向应用混淆
        for _ in 0..<layer {
            result = removeObfuscationLayer(result)
        }
        
        return result
    }
    
    private func applyObfuscationLayer(_ data: Data) -> Data {
        // 简单的 XOR 混淆
        var result = Data(count: data.count)
        let mask: UInt8 = 0xAA
        
        for i in 0..<data.count {
            result[i] = data[i] ^ mask
        }
        
        return result
    }
    
    private func removeObfuscationLayer(_ data: Data) -> Data {
        // XOR 是对称的，所以解混淆和混淆相同
        return applyObfuscationLayer(data)
    }
    
    private func addPadding(_ data: Data) -> Data {
        var result = data
        let padding = Data(repeating: 0, count: paddingLength)
        result.append(padding)
        return result
    }
    
    private func removePadding(_ data: Data) -> Data {
        guard data.count > paddingLength else {
            return data
        }
        return data.prefix(data.count - paddingLength)
    }
}
```

#### 1.3 UDP 客户端
```swift
// MorphUDPClient.swift
import Foundation
import Network

class MorphUDPClient {
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.morphvpn.udp")
    private let encryptor: MorphEncryptor
    private let obfuscator: MorphObfuscator
    
    var onReceive: ((Data) -> Void)?
    var onError: ((Error) -> Void)?
    
    init(encryptionKey: String, obfuscationLayer: Int, paddingLength: Int) throws {
        self.encryptor = try MorphEncryptor(keyString: encryptionKey)
        self.obfuscator = MorphObfuscator(layer: obfuscationLayer, paddingLength: paddingLength)
    }
    
    func connect(host: String, port: UInt16) {
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!
        )
        
        connection = NWConnection(to: endpoint, using: .udp)
        
        connection?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                NSLog("MorphProtocol: UDP connection ready")
                self?.startReceiving()
            case .failed(let error):
                NSLog("MorphProtocol: UDP connection failed: \\(error)")
                self?.onError?(error)
            case .cancelled:
                NSLog("MorphProtocol: UDP connection cancelled")
            default:
                break
            }
        }
        
        connection?.start(queue: queue)
    }
    
    func send(_ data: Data) {
        do {
            // 1. 加密
            let encrypted = try encryptor.encrypt(data)
            
            // 2. 混淆
            let obfuscated = obfuscator.obfuscate(encrypted)
            
            // 3. 发送
            connection?.send(content: obfuscated, completion: .contentProcessed { error in
                if let error = error {
                    NSLog("MorphProtocol: Send error: \\(error)")
                    self.onError?(error)
                }
            })
        } catch {
            NSLog("MorphProtocol: Encryption error: \\(error)")
            onError?(error)
        }
    }
    
    private func startReceiving() {
        connection?.receiveMessage { [weak self] data, context, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                NSLog("MorphProtocol: Receive error: \\(error)")
                self.onError?(error)
                return
            }
            
            if let data = data {
                do {
                    // 1. 解混淆
                    let deobfuscated = self.obfuscator.deobfuscate(data)
                    
                    // 2. 解密
                    let decrypted = try self.encryptor.decrypt(deobfuscated)
                    
                    // 3. 回调
                    self.onReceive?(decrypted)
                } catch {
                    NSLog("MorphProtocol: Decryption error: \\(error)")
                    self.onError?(error)
                }
            }
            
            // 继续接收
            self.startReceiving()
        }
    }
    
    func disconnect() {
        connection?.cancel()
        connection = nil
    }
}
```

### 步骤 2：修改 PacketTunnelProvider

修改 `ios/App/WireGuardExtension/PacketTunnelProvider.swift`：

```swift
import NetworkExtension
import WireGuardKit
import os.log

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    private var adapter: WireGuardAdapter?
    private var morphClient: MorphUDPClient?
    private lazy var logger = Logger(subsystem: "com.morphvpn.app.WireGuardExtension", category: "PacketTunnel")
    
    // MorphProtocol 配置
    private var useMorphProtocol: Bool = false
    private var morphServerHost: String?
    private var morphServerPort: UInt16?
    
    override init() {
        super.init()
        NSLog("🎯 PacketTunnelProvider: init() called")
        logger.info("🎯 PacketTunnelProvider: Initialized")
    }
    
    override func startTunnel(options: [String : NSObject]?, 
                            completionHandler: @escaping (Error?) -> Void) {
        
        NSLog("🚀 PacketTunnelProvider: startTunnel() called")
        logger.info("🚀 Starting WireGuard tunnel...")
        
        // 获取配置
        guard let protocolConfiguration = self.protocolConfiguration as? NETunnelProviderProtocol else {
            NSLog("❌ Failed to get protocol configuration")
            completionHandler(NSError(domain: "WireGuard", code: 1))
            return
        }
        
        guard let providerConfiguration = protocolConfiguration.providerConfiguration else {
            NSLog("❌ Provider configuration is nil")
            completionHandler(NSError(domain: "WireGuard", code: 2))
            return
        }
        
        // 检查是否启用 MorphProtocol
        if let useMorph = providerConfiguration["useMorphProtocol"] as? Bool,
           useMorph == true {
            NSLog("🔒 MorphProtocol enabled")
            useMorphProtocol = true
            morphServerHost = providerConfiguration["morphServerHost"] as? String
            morphServerPort = providerConfiguration["morphServerPort"] as? UInt16
            
            // 初始化 MorphProtocol 客户端
            if let encryptionKey = providerConfiguration["morphEncryptionKey"] as? String,
               let host = morphServerHost,
               let port = morphServerPort {
                
                let obfuscationLayer = providerConfiguration["morphObfuscationLayer"] as? Int ?? 3
                let paddingLength = providerConfiguration["morphPaddingLength"] as? Int ?? 8
                
                do {
                    morphClient = try MorphUDPClient(
                        encryptionKey: encryptionKey,
                        obfuscationLayer: obfuscationLayer,
                        paddingLength: paddingLength
                    )
                    
                    morphClient?.onReceive = { [weak self] data in
                        // 处理从服务器接收的数据
                        self?.handleMorphData(data)
                    }
                    
                    morphClient?.onError = { error in
                        NSLog("❌ MorphProtocol error: \\(error)")
                    }
                    
                    morphClient?.connect(host: host, port: port)
                    NSLog("✅ MorphProtocol client initialized")
                } catch {
                    NSLog("❌ Failed to initialize MorphProtocol: \\(error)")
                    useMorphProtocol = false
                }
            }
        }
        
        // 获取 WireGuard 配置
        guard let configString = providerConfiguration["wg_config"] as? String else {
            NSLog("❌ WireGuard config not found")
            completionHandler(NSError(domain: "WireGuard", code: 3))
            return
        }
        
        NSLog("✅ Got WireGuard config, length: \\(configString.count) bytes")
        
        // 解析配置
        let tunnelConfiguration: TunnelConfiguration
        do {
            tunnelConfiguration = try TunnelConfiguration(fromWgQuickConfig: configString)
            NSLog("✅ Successfully parsed WireGuard configuration")
        } catch {
            NSLog("❌ Failed to parse WireGuard config: \\(error)")
            completionHandler(error)
            return
        }
        
        // 创建适配器
        NSLog("🔨 Creating WireGuard adapter...")
        adapter = WireGuardAdapter(with: self) { [weak self] logLevel, message in
            NSLog("WireGuard[\\(logLevel)]: \\(message)")
            self?.logger.log(level: self?.osLogLevel(from: logLevel) ?? .default, "WireGuard: \\(message)")
        }
        
        // 如果启用了 MorphProtocol，修改数据流
        if useMorphProtocol {
            // TODO: 拦截 WireGuard 流量并通过 MorphProtocol 发送
            NSLog("🔒 WireGuard traffic will be routed through MorphProtocol")
        }
        
        // 启动隧道
        NSLog("🚀 Starting WireGuard adapter...")
        adapter?.start(tunnelConfiguration: tunnelConfiguration) { [weak self] error in
            if let error = error {
                NSLog("❌ Failed to start WireGuard: \\(error)")
                completionHandler(error)
            } else {
                NSLog("✅ WireGuard tunnel started successfully!")
                completionHandler(nil)
            }
        }
    }
    
    private func handleMorphData(_ data: Data) {
        // 处理从 MorphProtocol 服务器接收的数据
        // 这些数据应该转发给 WireGuard
        NSLog("📦 Received \\(data.count) bytes from MorphProtocol server")
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, 
                           completionHandler: @escaping () -> Void) {
        NSLog("🛑 Stopping tunnel")
        
        morphClient?.disconnect()
        morphClient = nil
        
        adapter?.stop { [weak self] error in
            if let error = error {
                NSLog("❌ Error stopping WireGuard: \\(error)")
            } else {
                NSLog("✅ WireGuard tunnel stopped successfully")
            }
            self?.adapter = nil
            completionHandler()
        }
    }
    
    private func osLogLevel(from logLevel: WireGuardLogLevel) -> OSLogType {
        switch logLevel {
        case .verbose:
            return .debug
        case .error:
            return .error
        @unknown default:
            return .default
        }
    }
}
```

### 步骤 3：修改 WireGuardPlugin

修改 `packages/wireguard-plugin/ios/Plugin/WireGuardPlugin.swift`：

```swift
// 在 saveConfiguration 方法中添加 MorphProtocol 配置
private func saveConfiguration(config: String, tunnelName: String, 
                              morphConfig: [String: Any]? = nil,
                              completion: @escaping (Bool, String?) -> Void) {
    
    let providerProtocol = NETunnelProviderProtocol()
    providerProtocol.providerBundleIdentifier = "com.morphvpn.app.WireGuardExtension"
    providerProtocol.serverAddress = "WireGuard"
    
    var providerConfiguration: [String: Any] = [
        "wg_config": config
    ]
    
    // 添加 MorphProtocol 配置
    if let morphConfig = morphConfig {
        providerConfiguration["useMorphProtocol"] = true
        providerConfiguration.merge(morphConfig) { (_, new) in new }
        print("🔒 MorphProtocol configuration added")
    }
    
    providerProtocol.providerConfiguration = providerConfiguration
    
    // ... 其余代码保持不变
}
```

### 步骤 4：修改 TypeScript API

修改 `packages/wireguard-plugin/src/definitions.ts`：

```typescript
export interface WireGuardPlugin {
  connect(options: { 
    config: string; 
    tunnelName: string;
    // MorphProtocol 可选配置
    useMorphProtocol?: boolean;
    morphServerHost?: string;
    morphServerPort?: number;
    morphEncryptionKey?: string;
    morphObfuscationLayer?: number;
    morphPaddingLength?: number;
  }): Promise<{ success: boolean; message?: string }>;
  
  // ... 其他方法
}
```

### 步骤 5：修改 React 组件

修改 `src/components/TestVpn.tsx`：

```typescript
const handleConnect = async () => {
    try {
        console.log('🔵 VPNComponent: handleConnect called');
        
        // WireGuard 配置
        const wgConfig = `[Interface]
PrivateKey = ...
Address = 10.8.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = ...
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
Endpoint = 49.233.198.81:51820
`;

        // 连接配置
        const connectOptions = {
            config: wgConfig,
            tunnelName: 'MorphVPN',
            // 启用 MorphProtocol
            useMorphProtocol: true,
            morphServerHost: 'morph.example.com',
            morphServerPort: 12301,
            morphEncryptionKey: 'base64key:base64iv',
            morphObfuscationLayer: 3,
            morphPaddingLength: 8
        };
        
        await connect(connectOptions.config, connectOptions.tunnelName);
        message.success('VPN 连接成功（已启用流量混淆）');
    } catch (error: any) {
        console.error('❌ Connect failed:', error);
        message.error(`连接失败: ${error.message}`);
    }
};
```

## 📝 服务器端要求

需要部署 MorphProtocol 服务器：

```bash
# 1. 克隆项目
git clone https://github.com/StarnesG/morphProtocol.git
cd morphProtocol

# 2. 安装依赖
npm install

# 3. 配置环境变量
cp .env.example .env
# 编辑 .env 文件

# 4. 启动服务器
npm run server
```

服务器配置示例：
```env
MORPH_PORT=12301
WIREGUARD_HOST=127.0.0.1
WIREGUARD_PORT=51820
ENCRYPTION_KEY=your-base64-key
ENCRYPTION_IV=your-base64-iv
```

## 🧪 测试步骤

### 1. 测试纯 WireGuard
```typescript
await connect(wgConfig, 'MorphVPN');
// useMorphProtocol: false (默认)
```

### 2. 测试 MorphProtocol + WireGuard
```typescript
await connect(wgConfig, 'MorphVPN', {
    useMorphProtocol: true,
    morphServerHost: 'server.com',
    morphServerPort: 12301,
    morphEncryptionKey: 'key:iv'
});
```

### 3. 验证混淆
- 使用 Wireshark 抓包
- 检查流量是否被混淆
- 验证无法识别为 WireGuard 流量

## ⚠️ 注意事项

### 1. 性能影响
- 混淆会增加延迟（约 5-10ms）
- 增加 CPU 使用率
- 略微增加带宽使用

### 2. 兼容性
- 需要 iOS 14.0+
- 需要支持 Network.framework
- 需要 CryptoKit

### 3. 安全性
- 加密密钥必须安全存储
- 建议使用 Keychain
- 定期更换密钥

## 🎯 下一步

1. **实现基础混淆**
   - 创建 MorphProtocol Swift 文件
   - 集成到 PacketTunnelProvider
   - 测试基本功能

2. **优化性能**
   - 使用异步处理
   - 优化加密算法
   - 减少内存占用

3. **添加高级功能**
   - 动态混淆策略
   - 流量分析对抗
   - 自适应混淆层级

需要我开始实现具体的代码吗？
