# MorphProtocol 集成测试指南

## 测试清单

### 阶段 1：集成前验证 ✅

- [x] MorphProtocol Swift 文件已创建
  - [x] `MorphEncryptor.swift`
  - [x] `MorphObfuscator.swift`
  - [x] `MorphUDPClient.swift`
- [x] 文档已创建
  - [x] 架构指南
  - [x] 实现指南
  - [x] 快速入门指南

### 阶段 2：Xcode 集成（需要用户操作）

- [ ] **将 MorphProtocol 文件添加到 Xcode 项目**
  1. 在 Xcode 中打开 `ios/App/App.xcworkspace`
  2. 右键点击 `WireGuardExtension` 文件夹
  3. 选择 "Add Files to App..."
  4. 导航到 `ios/App/WireGuardExtension/MorphProtocol/`
  5. 选择全部 3 个 Swift 文件
  6. **重要**：勾选 "Copy items if needed" 并选择 `WireGuardExtension` target
  7. 点击 "Add"

- [ ] **验证文件目标**
  1. 在 Xcode 中选择每个 MorphProtocol Swift 文件
  2. 打开文件检查器（右侧面板）
  3. 在 "Target Membership" 下，确保只勾选了 `WireGuardExtension`

- [ ] **构建 WireGuardExtension target**
  1. 在 Xcode 中选择 `WireGuardExtension` scheme
  2. Product → Build (⌘B)
  3. 验证没有编译错误

### 阶段 3：代码集成

#### 3.1 修改 PacketTunnelProvider

- [ ] **打开 `PacketTunnelProvider.swift`**
- [ ] **添加 MorphUDPClient 属性**（在现有属性之后）：
```swift
private var morphClient: MorphUDPClient?
```

- [ ] **修改 `startTunnel` 方法**以初始化 MorphProtocol：
```swift
override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
    // 检查是否应该使用 MorphProtocol
    if let useMorph = options?["useMorphProtocol"] as? Bool, useMorph {
        let encryptionKey = options?["morphEncryptionKey"] as? String ?? ""
        let serverHost = options?["morphServerHost"] as? String ?? ""
        let serverPort = options?["morphServerPort"] as? Int ?? 0
        let layerCount = options?["morphLayerCount"] as? Int ?? 3
        let paddingLength = options?["morphPaddingLength"] as? Int ?? 8
        
        wg_log(.info, message: "初始化 MorphProtocol: \(serverHost):\(serverPort)")
        
        do {
            morphClient = try MorphUDPClient(
                encryptionKey: encryptionKey,
                serverHost: serverHost,
                serverPort: serverPort,
                layerCount: layerCount,
                paddingLength: paddingLength
            )
            
            morphClient?.onStateChange = { state in
                wg_log(.info, message: "MorphProtocol 状态: \(state)")
            }
            
            morphClient?.onError = { error in
                wg_log(.error, message: "MorphProtocol 错误: \(error)")
            }
            
            morphClient?.start()
            wg_log(.info, message: "MorphProtocol 启动成功")
        } catch {
            wg_log(.error, message: "初始化 MorphProtocol 失败: \(error)")
        }
    }
    
    // 继续现有的 WireGuard 初始化...
    // [保留这里的现有代码]
}
```

- [ ] **修改 `stopTunnel` 方法**以清理 MorphProtocol：
```swift
override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
    // 如果 MorphProtocol 正在运行，停止它
    if let morphClient = morphClient {
        wg_log(.info, message: "停止 MorphProtocol")
        morphClient.stop()
        self.morphClient = nil
    }
    
    // 继续现有的 WireGuard 清理...
    // [保留这里的现有代码]
}
```

#### 3.2 修改 WireGuardPlugin

- [ ] **打开 `packages/wireguard-plugin/ios/Plugin/WireGuardPlugin.swift`**
- [ ] **更新 `connect` 方法**以接受 MorphProtocol 参数：
```swift
@objc func connect(_ call: CAPPluginCall) {
    guard let config = call.getString("config") else {
        call.reject("需要配置")
        return
    }
    
    // 解析 MorphProtocol 选项
    let useMorphProtocol = call.getBool("useMorphProtocol") ?? false
    let morphEncryptionKey = call.getString("morphEncryptionKey") ?? ""
    let morphServerHost = call.getString("morphServerHost") ?? ""
    let morphServerPort = call.getInt("morphServerPort") ?? 0
    let morphLayerCount = call.getInt("morphLayerCount") ?? 3
    let morphPaddingLength = call.getInt("morphPaddingLength") ?? 8
    
    // 创建选项字典
    var options: [String: NSObject] = [:]
    if useMorphProtocol {
        options["useMorphProtocol"] = NSNumber(value: true)
        options["morphEncryptionKey"] = morphEncryptionKey as NSObject
        options["morphServerHost"] = morphServerHost as NSObject
        options["morphServerPort"] = NSNumber(value: morphServerPort)
        options["morphLayerCount"] = NSNumber(value: morphLayerCount)
        options["morphPaddingLength"] = NSNumber(value: morphPaddingLength)
    }
    
    // 使用选项启动隧道
    // [继续现有的隧道启动代码，传递 options]
}
```

#### 3.3 TypeScript 定义

- [ ] **创建/更新 `packages/wireguard-plugin/src/definitions.ts`**：
```typescript
export interface WireGuardConfig {
  config: string;
  tunnelName: string;
  useMorphProtocol?: boolean;
  morphEncryptionKey?: string;
  morphServerHost?: string;
  morphServerPort?: number;
  morphLayerCount?: number;
  morphPaddingLength?: number;
}

export interface WireGuardPlugin {
  connect(config: WireGuardConfig): Promise<void>;
  disconnect(): Promise<void>;
  getStatus(): Promise<{ connected: boolean }>;
}
```

### 阶段 4：生成测试密钥

- [ ] **使用 Node.js 生成加密密钥**：
```bash
node -e "const crypto = require('crypto'); const key = crypto.randomBytes(32).toString('base64'); const iv = crypto.randomBytes(12).toString('base64'); console.log(key + ':' + iv);"
```

- [ ] **保存输出**（格式：`base64key:base64iv`）
- [ ] **示例输出**：`dGVzdGtleXRlc3RrZXl0ZXN0a2V5dGVzdGtleQ==:dGVzdGl2dGVzdGl2`

### 阶段 5：React 组件测试

- [ ] **更新 VPN 连接组件**以使用 MorphProtocol：
```typescript
import { Plugins } from '@capacitor/core';
const { WireGuard } = Plugins;

async function connectWithMorph() {
  try {
    await WireGuard.connect({
      config: wireguardConfig,
      tunnelName: 'MorphVPN',
      useMorphProtocol: true,
      morphEncryptionKey: '第4步生成的密钥',
      morphServerHost: 'morph.example.com',
      morphServerPort: 51821,
      morphLayerCount: 3,
      morphPaddingLength: 8
    });
    console.log('已使用 MorphProtocol 连接');
  } catch (error) {
    console.error('连接失败:', error);
  }
}
```

### 阶段 6：构建和部署

- [ ] **构建应用**：
```bash
npm run build
npx cap sync ios
```

- [ ] **在 Xcode 中打开**：
```bash
npx cap open ios
```

- [ ] **选择真实的 iOS 设备**（VPN 扩展在模拟器中不工作）
- [ ] **构建并运行** (⌘R)

### 阶段 7：运行时测试

#### 7.1 基本连接测试

- [ ] **在设备上启动应用**
- [ ] **尝试不使用 MorphProtocol 连接**：
  - 应该正常连接到 WireGuard
  - 验证状态栏中出现 VPN 图标
  - 测试互联网连接
  - 断开连接

- [ ] **尝试使用 MorphProtocol 连接**：
  - 在 UI 中启用 MorphProtocol
  - 提供加密密钥和服务器详细信息
  - 尝试连接
  - 检查状态栏中的 VPN 图标

#### 7.2 日志验证

- [ ] **在 Mac 上打开 Console.app**
- [ ] **连接 iOS 设备**
- [ ] **过滤日志**：搜索 "MorphProtocol" 或 "WireGuard"
- [ ] **预期的日志消息**：
  ```
  初始化 MorphProtocol: morph.example.com:51821
  MorphProtocol 状态: ready
  MorphProtocol 启动成功
  ```

- [ ] **检查错误**：
  - 加密密钥解析错误
  - UDP 连接失败
  - 状态转换问题

#### 7.3 网络流量分析

- [ ] **在 Mac 上安装 Wireshark**
- [ ] **启用 iOS 设备数据包捕获**：
  ```bash
  # 创建远程虚拟接口
  rvictl -s [设备UDID]
  ```

- [ ] **在 rvi0 接口上捕获流量**
- [ ] **过滤 UDP 流量**到 MorphProtocol 服务器端口
- [ ] **验证混淆**：
  - 流量不应显示 WireGuard 握手模式
  - 数据包应该看起来随机/加密
  - 没有明文协议标识符

### 阶段 8：错误场景

- [ ] **测试无效的加密密钥**：
  - 提供格式错误的密钥
  - 预期：记录错误，连接优雅失败

- [ ] **测试无法访问的服务器**：
  - 提供不存在的服务器地址
  - 预期：超时，记录错误

- [ ] **测试缺少参数**：
  - 省略加密密钥
  - 预期：记录错误，回退到标准 WireGuard

- [ ] **测试连接中断**：
  - 成功连接
  - 禁用 WiFi/蜂窝网络
  - 重新启用网络
  - 预期：自动重新连接

## 已知限制

### 当前实现状态

✅ **已实现**：
- MorphProtocol 加密（AES-GCM）
- 多层混淆（XOR + 位旋转）
- 随机填充
- 带状态管理的 UDP 客户端
- PacketTunnelProvider 中的集成钩子

⚠️ **部分实现**：
- 流量拦截（需要额外的数据包转发逻辑）
- 自动回退到标准 WireGuard

❌ **尚未实现**：
- 从 WireGuard 隧道完整捕获数据包
- 通过 MorphProtocol 的双向流量转发
- 高吞吐量场景的性能优化
- 服务器端 MorphProtocol 实现（独立项目）

### iOS VPN 限制

1. **单一 VPN 连接**：iOS 只允许一个活动的 VPN 连接
2. **Network Extension 沙箱**：对系统网络的访问受限
3. **后台执行**：VPN 扩展有严格的资源限制
4. **调试**：无法在模拟器中调试 Network Extensions

## 故障排除

### 构建错误

**错误**：`Cannot find 'MorphUDPClient' in scope`
- **解决方案**：验证 MorphProtocol 文件已添加到 WireGuardExtension target

**错误**：`Module 'CryptoKit' not found`
- **解决方案**：确保 Xcode 项目设置中的部署目标为 iOS 13.0+

**错误**：`Use of unresolved identifier 'wg_log'`
- **解决方案**：在 PacketTunnelProvider 中导入 WireGuardKit 日志

### 运行时错误

**错误**：`Encryption key format invalid`
- **解决方案**：验证密钥格式为 `base64key:base64iv`，长度正确

**错误**：`UDP connection failed`
- **解决方案**：检查服务器地址、端口和防火墙规则

**错误**：`VPN connection established but no internet`
- **解决方案**：验证 MorphProtocol 服务器正在将流量转发到 WireGuard 端点

### 性能问题

**症状**：连接速度慢
- **原因**：多层加密（MorphProtocol + WireGuard）
- **解决方案**：将 `morphLayerCount` 减少到 1-2，减少 `morphPaddingLength`

**症状**：电池消耗高
- **原因**：持续的 UDP 保活数据包
- **解决方案**：根据网络条件实现自适应保活间隔

## 下一步

完成此测试清单后：

1. **记录测试结果**在新文件 `MORPHPROTOCOL_TEST_RESULTS.md` 中
2. **报告任何问题**，附带详细日志和重现步骤
3. **根据性能指标优化配置**
4. **实现服务器端** MorphProtocol 端点（如果尚未完成）
5. **考虑高级功能**：
   - 流量模式分析抵抗
   - 动态混淆参数调整
   - 通过 MorphProtocol 中继的多跳路由

## 成功标准

当满足以下条件时，集成被认为是成功的：

- ✅ 应用构建无错误
- ✅ VPN 在启用 MorphProtocol 的情况下连接
- ✅ 互联网流量通过连接流动
- ✅ 日志显示 MorphProtocol 初始化和状态变化
- ✅ 网络捕获显示混淆流量（无 WireGuard 模式）
- ✅ 连接保持稳定 5 分钟以上
- ✅ 网络中断后重新连接工作

## 支持

如有问题或疑问：
1. 在 Console.app 中检查日志以获取详细的错误消息
2. 查看此存储库中的实现指南
3. 验证服务器端 MorphProtocol 正在运行且可访问
4. 测试标准 WireGuard 连接（不使用 MorphProtocol）以隔离问题
