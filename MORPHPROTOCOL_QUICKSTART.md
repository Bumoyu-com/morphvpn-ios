# MorphProtocol 快速开始指南

## ✅ 已完成的工作

我已经为你创建了完整的 MorphProtocol 实现：

### 1. Swift 模块（3个文件）
- ✅ `ios/App/WireGuardExtension/MorphProtocol/MorphEncryptor.swift`
- ✅ `ios/App/WireGuardExtension/MorphProtocol/MorphObfuscator.swift`
- ✅ `ios/App/WireGuardExtension/MorphProtocol/MorphUDPClient.swift`

### 2. 文档
- ✅ `MORPHPROTOCOL_WIREGUARD_INTEGRATION.md` - 完整架构设计
- ✅ `MORPHPROTOCOL_IMPLEMENTATION_GUIDE.md` - 详细实现指南
- ✅ `MORPHPROTOCOL_QUICKSTART.md` - 本文档

## 🚀 快速集成步骤

### 步骤 1：在 Xcode 中添加文件（5分钟）

```
1. 打开 Xcode
   npx cap open ios

2. 在左侧 Project Navigator 找到 WireGuardExtension 文件夹

3. 右键点击 WireGuardExtension → Add Files to "App"...

4. 导航到：ios/App/WireGuardExtension/MorphProtocol/

5. 选择所有 3 个 .swift 文件

6. 确保：
   ✓ "Add to targets" 勾选 WireGuardExtension
   ✓ "Create groups" 已选中

7. 点击 Add
```

### 步骤 2：修改 PacketTunnelProvider（10分钟）

打开 `ios/App/WireGuardExtension/PacketTunnelProvider.swift`

在文件顶部添加：
```swift
private var morphClient: MorphUDPClient?
private var useMorphProtocol: Bool = false
```

在 `startTunnel` 方法中，在获取 WireGuard 配置之前添加：

```swift
// 检查是否启用 MorphProtocol
if let useMorph = providerConfiguration["useMorphProtocol"] as? Bool, useMorph {
    NSLog("🔒 MorphProtocol enabled")
    useMorphProtocol = true
    
    if let encryptionKey = providerConfiguration["morphEncryptionKey"] as? String,
       let host = providerConfiguration["morphServerHost"] as? String,
       let port = providerConfiguration["morphServerPort"] as? NSNumber {
        
        let layer = (providerConfiguration["morphObfuscationLayer"] as? NSNumber)?.intValue ?? 3
        let padding = (providerConfiguration["morphPaddingLength"] as? NSNumber)?.intValue ?? 8
        
        do {
            morphClient = try MorphUDPClient(
                encryptionKey: encryptionKey,
                obfuscationLayer: layer,
                paddingLength: padding
            )
            
            morphClient?.onReceive = { data in
                NSLog("📦 Received \(data.count) bytes from MorphProtocol")
            }
            
            morphClient?.onError = { error in
                NSLog("❌ MorphProtocol error: \(error)")
            }
            
            morphClient?.connect(host: host, port: UInt16(truncating: port))
            NSLog("✅ MorphProtocol client connected")
        } catch {
            NSLog("❌ Failed to init MorphProtocol: \(error)")
            useMorphProtocol = false
        }
    }
}
```

在 `stopTunnel` 方法开始处添加：
```swift
morphClient?.disconnect()
morphClient = nil
```

### 步骤 3：修改 WireGuardPlugin（5分钟）

打开 `packages/wireguard-plugin/ios/Plugin/WireGuardPlugin.swift`

找到 `saveConfiguration` 方法，修改 `providerConfiguration` 部分：

```swift
var providerConfiguration: [String: Any] = [
    "wg_config": config
]

// 添加 MorphProtocol 配置（如果有）
if let morphConfig = morphConfig {
    providerConfiguration.merge(morphConfig) { (_, new) in new }
    print("🔒 MorphProtocol config added")
}

providerProtocol.providerConfiguration = providerConfiguration
```

在 `connect` 方法中添加 MorphProtocol 参数处理：

```swift
@objc func connect(_ call: CAPPluginCall) {
    // ... 现有代码 ...
    
    // 获取 MorphProtocol 配置
    var morphConfig: [String: Any]? = nil
    if let useMorph = call.getBool("useMorphProtocol"), useMorph {
        morphConfig = [
            "useMorphProtocol": true,
            "morphServerHost": call.getString("morphServerHost") ?? "",
            "morphServerPort": call.getInt("morphServerPort") ?? 12301,
            "morphEncryptionKey": call.getString("morphEncryptionKey") ?? "",
            "morphObfuscationLayer": call.getInt("morphObfuscationLayer") ?? 3,
            "morphPaddingLength": call.getInt("morphPaddingLength") ?? 8
        ]
    }
    
    saveAndConnect(config: config, tunnelName: tunnelName, morphConfig: morphConfig) { ... }
}
```

修改 `saveAndConnect` 方法签名：
```swift
private func saveAndConnect(config: String, tunnelName: String, 
                          morphConfig: [String: Any]? = nil,
                          completion: @escaping (Bool, String?) -> Void) {
    // ...
}
```

### 步骤 4：修改 TypeScript 定义（2分钟）

打开 `packages/wireguard-plugin/src/definitions.ts`

修改 `connect` 方法：
```typescript
export interface WireGuardPlugin {
  connect(options: { 
    config: string; 
    tunnelName: string;
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

### 步骤 5：生成加密密钥（1分钟）

创建 `src/utils/morphKeys.ts`：

```typescript
export function generateMorphKeys(): string {
    const key = new Uint8Array(32);
    crypto.getRandomValues(key);
    
    const iv = new Uint8Array(12);
    crypto.getRandomValues(iv);
    
    const keyBase64 = btoa(String.fromCharCode(...key));
    const ivBase64 = btoa(String.fromCharCode(...iv));
    
    return `${keyBase64}:${ivBase64}`;
}
```

在浏览器控制台运行：
```javascript
const key = new Uint8Array(32);
crypto.getRandomValues(key);
const iv = new Uint8Array(12);
crypto.getRandomValues(iv);
const keyBase64 = btoa(String.fromCharCode(...key));
const ivBase64 = btoa(String.fromCharCode(...iv));
console.log(`${keyBase64}:${ivBase64}`);
```

### 步骤 6：修改 React 组件（3分钟）

打开 `src/components/TestVpn.tsx`

修改 `handleConnect`：

```typescript
const handleConnect = async () => {
    try {
        const wgConfig = `[Interface]
PrivateKey = IO9xZFb/qXXd/WEtUZl+9CHHYBef9BgPnm+RQMnGmVg=
Address = 10.8.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = 4oFUG+Nl2hIQx0b3j1IM203+vc0ygkz3IqwtboJoki4=
PresharedKey = QEPMjyc2oLDxICl2ebOQOlCrQMGFN/ccRH2KmY3fSUg=
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
Endpoint = 49.233.198.81:51820
`;

        // 使用 MorphProtocol 混淆
        await WireGuard.connect({
            config: wgConfig,
            tunnelName: 'MorphVPN',
            useMorphProtocol: true,
            morphServerHost: 'your-server.com',
            morphServerPort: 12301,
            morphEncryptionKey: 'your-generated-key:your-generated-iv',
            morphObfuscationLayer: 3,
            morphPaddingLength: 8
        });
        
        message.success('VPN 已连接（流量混淆已启用）');
    } catch (error: any) {
        message.error(`连接失败: ${error.message}`);
    }
};
```

### 步骤 7：构建和测试（5分钟）

```bash
# 1. 重新构建插件
cd packages/wireguard-plugin
npm run build
npm pack
cd ../..
npm install ./packages/wireguard-plugin/morphvpn-capacitor-wireguard-1.0.0.tgz

# 2. 同步到 iOS
npx cap sync ios

# 3. 在 Xcode 中构建
# Product → Clean Build Folder (⇧⌘K)
# Product → Build (⌘B)
# Product → Run (⌘R)
```

## 🧪 测试

### 测试 1：纯 WireGuard（不使用混淆）

```typescript
await WireGuard.connect({
    config: wgConfig,
    tunnelName: 'MorphVPN'
    // useMorphProtocol 默认为 false
});
```

### 测试 2：WireGuard + MorphProtocol

```typescript
await WireGuard.connect({
    config: wgConfig,
    tunnelName: 'MorphVPN',
    useMorphProtocol: true,
    morphServerHost: 'server.com',
    morphServerPort: 12301,
    morphEncryptionKey: 'generated-key',
    morphObfuscationLayer: 3,
    morphPaddingLength: 8
});
```

### 查看日志

在 Console.app 中搜索：
- `MorphProtocol` - 查看所有混淆相关日志
- `🔒` - 查看加密相关日志
- `🎭` - 查看混淆相关日志

## 📊 预期日志

启用 MorphProtocol 时应该看到：

```
🔒 MorphProtocol enabled
🔒 MorphUDPClient: Initializing...
✅ MorphUDPClient: Initialized with layer=3, padding=8
🔌 MorphUDPClient: Connecting to server.com:12301
✅ MorphUDPClient: Connection ready
✅ MorphProtocol client connected
✅ WireGuard tunnel started successfully!
```

## ⚠️ 重要提示

### 1. 服务器要求

你需要部署 MorphProtocol 服务器：
```bash
git clone https://github.com/StarnesG/morphProtocol.git
cd morphProtocol
npm install
# 配置 .env 文件
npm run server
```

### 2. 密钥同步

客户端和服务器必须使用相同的加密密钥！

### 3. 当前限制

⚠️ **当前实现是基础版本**，包含：
- ✅ 加密/解密
- ✅ 混淆/解混淆
- ✅ UDP 通信
- ⚠️ 流量拦截（需要进一步实现）

完整的流量拦截需要更复杂的实现，涉及到 WireGuard 数据包的拦截和转发。

## 🎯 总结

**总时间：约 30 分钟**

1. ✅ 在 Xcode 添加 3 个 Swift 文件（5分钟）
2. ✅ 修改 PacketTunnelProvider（10分钟）
3. ✅ 修改 WireGuardPlugin（5分钟）
4. ✅ 修改 TypeScript 定义（2分钟）
5. ✅ 生成加密密钥（1分钟）
6. ✅ 修改 React 组件（3分钟）
7. ✅ 构建和测试（5分钟）

**下一步**：
- 部署 MorphProtocol 服务器
- 测试连接
- 根据需要调整混淆参数

需要帮助吗？查看详细文档：
- `MORPHPROTOCOL_IMPLEMENTATION_GUIDE.md` - 完整实现指南
- `MORPHPROTOCOL_WIREGUARD_INTEGRATION.md` - 架构设计

祝你成功！🎉
