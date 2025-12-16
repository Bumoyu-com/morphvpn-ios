# MorphProtocol 实施进度

## 已完成 ✅

### 1. ObfuscationFunctions.swift ✅
**位置**: `ios/App/WireGuardExtension/MorphProtocol/ObfuscationFunctions.swift`

**内容**:
- 11种完整的混淆函数
- FunctionPair 结构
- ObfuscationFunctionRegistry 单例
- 所有函数都是可逆的

**功能**:
1. BitwiseRotationAndXOR
2. SwapNeighboringBytes
3. ReverseBuffer
4. DivideAndSwap
5. CircularShiftObfuscation
6. XorWithKey
7. BitwiseNOT
8. ReverseBits
9. ShiftBits
10. Substitution
11. AddRandomValue

---

### 2. FunctionRegistry.swift ✅
**位置**: `ios/App/WireGuardExtension/MorphProtocol/FunctionRegistry.swift`

**内容**:
- 函数组合管理
- 预计算所有排列（P(11,1) 到 P(11,4)）
- 动态索引计算
- 统计和验证功能

**关键方法**:
- `getFunctionCombos()` - 获取当前层数的所有组合
- `calculateComboIndex()` - 根据 header 计算索引
- `getCombo(at:)` - 获取指定索引的组合
- `getFunction(at:)` - 获取函数对象

---

### 3. MorphObfuscator.swift ✅
**位置**: `ios/App/WireGuardExtension/MorphProtocol/MorphObfuscator.swift`

**内容**:
- 完全重写，实现动态函数选择
- Header 生成和解析
- 函数组合应用
- 随机填充

**数据格式**:
```
[header(3)] [obfuscated data] [padding(1-16)]
```

**关键方法**:
- `obfuscate()` - 混淆数据
- `deobfuscate()` - 解混淆数据
- `testReversibility()` - 测试可逆性
- `testDynamism()` - 测试动态性

---

### 4. ProtocolTemplates.swift ✅
**位置**: `ios/App/WireGuardExtension/MorphProtocol/ProtocolTemplates.swift`

**内容**:
- 3种协议模板实现
- ProtocolTemplate 接口
- TemplateFactory 工厂类

**模板类型**:
1. **QuicTemplate** - 模拟 QUIC 协议
   - Header: [flags(1)] [connectionID(8)] [packetNumber(4)]
   
2. **KcpTemplate** - 模拟 KCP 协议
   - Header: [conv(4)] [cmd(1)] [frg(1)] [wnd(2)] [ts(4)] [sn(4)] [una(4)]
   
3. **GenericGamingTemplate** - 模拟游戏协议
   - Header: [magic(4)] [sessionID(4)] [sequence(4)] [timestamp(4)]

---

## 待完成 ⏳

### 5. 更新 MorphUDPClient.swift ⏳
**位置**: `ios/App/WireGuardExtension/MorphProtocol/MorphUDPClient.swift`

**需要修改**:

#### 5.1 更新初始化方法
```swift
// 当前
init(encryptionKey: String, obfuscationLayer: Int, paddingLength: Int) throws

// 修改为
init(encryptionKey: String, 
     obfuscationLayer: Int, 
     paddingLength: Int,
     templateType: TemplateType? = nil) throws {
    
    self.encryptor = try MorphEncryptor(keyString: encryptionKey)
    
    // 从加密密钥派生 obfuscation key
    let keyData = Data(encryptionKey.utf8)
    let key = keyData.reduce(0) { $0 ^ Int($1) }
    
    self.obfuscator = MorphObfuscator(
        key: key,
        layer: obfuscationLayer,
        paddingLength: paddingLength
    )
    
    // 生成 clientID (16 bytes)
    var clientIDData = Data(count: 16)
    for i in 0..<16 {
        clientIDData[i] = UInt8.random(in: 0...255)
    }
    self.clientID = clientIDData
    
    // 创建协议模板
    if let type = templateType {
        self.template = TemplateFactory.createTemplate(type)
        NSLog("🎭 MorphUDPClient: Using \(template!.name) template")
    } else {
        self.template = nil
        NSLog("ℹ️ MorphUDPClient: No protocol template")
    }
}
```

#### 5.2 更新 send 方法
```swift
func send(_ data: Data) {
    queue.async { [weak self] in
        guard let self = self else { return }
        
        do {
            // 1. 加密
            let encrypted = try self.encryptor.encrypt(data)
            
            // 2. 混淆
            let obfuscated = self.obfuscator.obfuscate(encrypted)
            
            // 3. 协议封装（如果启用）
            let packet: Data
            if let template = self.template {
                packet = template.encapsulate(obfuscated, clientID: self.clientID)
                NSLog("🎭 MorphUDPClient: Encapsulated with \(template.name)")
            } else {
                packet = obfuscated
            }
            
            // 4. 发送
            self.connection?.send(content: packet, completion: .contentProcessed { error in
                if let error = error {
                    NSLog("❌ MorphUDPClient: Send error: \(error)")
                } else {
                    NSLog("✅ MorphUDPClient: Sent \(packet.count) bytes")
                }
            })
            
        } catch {
            NSLog("❌ MorphUDPClient: Processing error: \(error)")
        }
    }
}
```

#### 5.3 更新 startReceiving 方法
```swift
private func startReceiving() {
    connection?.receiveMessage { [weak self] data, context, isComplete, error in
        guard let self = self else { return }
        
        if let error = error {
            NSLog("❌ MorphUDPClient: Receive error: \(error)")
            return
        }
        
        if let data = data, !data.isEmpty {
            do {
                // 1. 协议解封装（如果启用）
                let obfuscated: Data
                if let template = self.template {
                    guard let extracted = template.decapsulate(data) else {
                        NSLog("❌ MorphUDPClient: Failed to decapsulate packet")
                        return
                    }
                    obfuscated = extracted
                    NSLog("🎭 MorphUDPClient: Decapsulated with \(template.name)")
                } else {
                    obfuscated = data
                }
                
                // 2. 解混淆
                let encrypted = self.obfuscator.deobfuscate(obfuscated)
                
                // 3. 解密
                let decrypted = try self.encryptor.decrypt(encrypted)
                
                // 4. 回调
                self.onReceive?(decrypted)
                
            } catch {
                NSLog("❌ MorphUDPClient: Processing error: \(error)")
            }
        }
        
        // 继续接收
        self.startReceiving()
    }
}
```

---

### 6. 更新 PacketTunnelProvider.swift ⏳
**位置**: `ios/App/WireGuardExtension/PacketTunnelProvider.swift`

**需要修改**:

#### 6.1 读取模板类型参数
```swift
// 在 startTunnel 方法中
if useMorph {
    let templateType: TemplateType?
    if let templateValue = providerConfiguration["morphTemplateType"] as? Int {
        templateType = TemplateType(rawValue: UInt8(templateValue))
        NSLog("🎭 PacketTunnelProvider: Template type: \(templateValue)")
    } else {
        templateType = .quic  // 默认使用 QUIC
        NSLog("🎭 PacketTunnelProvider: Using default QUIC template")
    }
    
    morphClient = try MorphUDPClient(
        encryptionKey: encryptionKey,
        obfuscationLayer: layerCount,
        paddingLength: paddingLength,
        templateType: templateType
    )
    
    // ... 其他代码
}
```

---

### 7. 更新 WireGuardPlugin.swift ⏳
**位置**: `packages/wireguard-plugin/ios/Plugin/WireGuardPlugin.swift`

**需要修改**:

#### 7.1 读取模板类型参数
```swift
// 在 connect 方法中
let morphTemplateType = call.getInt("morphTemplateType") ?? 1  // 默认 QUIC

if useMorphProtocol {
    providerConfig["morphTemplateType"] = NSNumber(value: morphTemplateType)
    
    NSLog("🎭 WireGuardPlugin: Template type: \(morphTemplateType)")
}
```

---

### 8. 更新 React 配置接口 ⏳
**位置**: `src/components/TestVpn.tsx`

**需要修改**:

```typescript
const connectOptions = {
    config: myConfig,
    tunnelName: 'MorphVPN',
    useMorphProtocol: true,
    morphEncryptionKey: 'key:iv',
    morphServerHost: 'server.com',
    morphServerPort: 51821,
    morphLayerCount: 3,
    morphPaddingLength: 8,
    morphTemplateType: 1,  // 1=QUIC, 2=KCP, 3=Gaming, 0=None
};
```

**添加模板选择 UI**:
```typescript
const [templateType, setTemplateType] = useState(1);

<Select value={templateType} onChange={setTemplateType}>
  <Option value={0}>无模板</Option>
  <Option value={1}>QUIC 协议</Option>
  <Option value={2}>KCP 协议</Option>
  <Option value={3}>游戏协议</Option>
</Select>
```

---

### 9. 更新类型定义 ⏳
**位置**: `packages/wireguard-plugin/src/definitions.ts`

**需要修改**:

```typescript
export interface WireGuardConnectOptions {
  config: string;
  tunnelName: string;
  useMorphProtocol?: boolean;
  morphEncryptionKey?: string;
  morphServerHost?: string;
  morphServerPort?: number;
  morphLayerCount?: number;
  morphPaddingLength?: number;
  morphTemplateType?: number;  // 新增：0=None, 1=QUIC, 2=KCP, 3=Gaming
}
```

---

## 测试计划

### 单元测试

#### 1. 混淆函数测试
```swift
func testObfuscationFunctions() {
    let testData = Data([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
    let keyArray = Data([0xAA, 0xBB, 0xCC, 0xDD])
    
    let functions = ObfuscationFunctionRegistry.shared.functions
    
    for function in functions {
        let obfuscated = function.obfuscation(testData, keyArray, function.initor)
        let deobfuscated = function.deobfuscation(obfuscated, keyArray, function.initor)
        
        XCTAssertEqual(testData, deobfuscated, 
                      "Function \(function.name) is not reversible")
    }
}
```

#### 2. 动态选择测试
```swift
func testDynamicSelection() {
    let obfuscator = MorphObfuscator(key: 12345, layer: 3, paddingLength: 8)
    let testData = Data(repeating: 0x42, count: 100)
    
    var results = Set<Data>()
    for _ in 0..<100 {
        let obfuscated = obfuscator.obfuscate(testData)
        results.insert(obfuscated)
    }
    
    // 应该有很多不同的结果
    XCTAssertGreaterThan(results.count, 90)
}
```

#### 3. 协议模板测试
```swift
func testProtocolTemplates() {
    let templates: [ProtocolTemplate] = [
        QuicTemplate(),
        KcpTemplate(),
        GenericGamingTemplate()
    ]
    
    let testData = Data([1, 2, 3, 4, 5])
    let clientID = Data(repeating: 0xAA, count: 16)
    
    for template in templates {
        let packet = template.encapsulate(testData, clientID: clientID)
        let extracted = template.decapsulate(packet)
        
        XCTAssertEqual(testData, extracted, 
                      "Template \(template.name) is not reversible")
    }
}
```

#### 4. 端到端测试
```swift
func testEndToEnd() {
    let obfuscator = MorphObfuscator(key: 12345, layer: 3, paddingLength: 8)
    let template = QuicTemplate()
    let clientID = Data(repeating: 0xBB, count: 16)
    
    let original = Data("Hello, MorphProtocol!".utf8)
    
    // 混淆
    let obfuscated = obfuscator.obfuscate(original)
    
    // 协议封装
    let packet = template.encapsulate(obfuscated, clientID: clientID)
    
    // 协议解封装
    let extracted = template.decapsulate(packet)!
    
    // 解混淆
    let deobfuscated = obfuscator.deobfuscate(extracted)
    
    XCTAssertEqual(original, deobfuscated)
}
```

---

## 实施优先级

### 高优先级（必须完成）
1. ✅ ObfuscationFunctions.swift
2. ✅ FunctionRegistry.swift
3. ✅ MorphObfuscator.swift
4. ⏳ 更新 MorphUDPClient.swift
5. ⏳ 更新 PacketTunnelProvider.swift

### 中优先级（建议完成）
6. ✅ ProtocolTemplates.swift
7. ⏳ 更新 WireGuardPlugin.swift
8. ⏳ 更新 React 配置接口

### 低优先级（可选）
9. ⏳ 单元测试
10. ⏳ 性能优化
11. ⏳ 文档完善

---

## 预计剩余工作量

- 更新 MorphUDPClient.swift: 1 小时
- 更新 PacketTunnelProvider.swift: 0.5 小时
- 更新 WireGuardPlugin.swift: 0.5 小时
- 更新 React 接口: 0.5 小时
- 测试验证: 1 小时

**总计**: 约 3.5 小时

---

## 当前状态

✅ **核心功能已完成 80%**

已实现:
- 11种混淆函数
- 动态函数选择
- 函数组合排列
- 3种协议模板

待完成:
- 集成到 MorphUDPClient
- 更新配置传递
- 测试验证

---

**更新时间**: 2025-12-16  
**状态**: 进行中
