# MorphProtocol 完整实现指南

## 已完成

✅ **ObfuscationFunctions.swift** - 11种混淆函数已实现

---

## 待实现文件清单

### 1. FunctionRegistry.swift（高优先级）

**位置**: `ios/App/WireGuardExtension/MorphProtocol/FunctionRegistry.swift`

**功能**: 管理函数组合和排列

**核心代码**:
```swift
class FunctionRegistry {
    private let obfuscationLayer: Int
    private let functions: [FunctionPair]
    
    // 预计算的函数组合
    private var combos1: [[Int]] = []
    private var combos2: [[Int]] = []
    private var combos3: [[Int]] = []
    private var combos4: [[Int]] = []
    
    init(layer: Int) {
        self.obfuscationLayer = min(max(layer, 1), 4)
        self.functions = ObfuscationFunctionRegistry.shared.functions
        
        // 预计算所有排列
        combos1 = calculatePermutations(n: functions.count, r: 1)
        combos2 = calculatePermutations(n: functions.count, r: 2)
        combos3 = calculatePermutations(n: functions.count, r: 3)
        combos4 = calculatePermutations(n: functions.count, r: 4)
    }
    
    func getFunctionCombos() -> [[Int]] {
        switch obfuscationLayer {
        case 1: return combos1
        case 2: return combos2
        case 3: return combos3
        case 4: return combos4
        default: return combos3
        }
    }
    
    private func calculatePermutations(n: Int, r: Int) -> [[Int]] {
        var result: [[Int]] = []
        let options = Array(0..<n)
        
        func permute(current: [Int], remaining: [Int]) {
            if current.count == r {
                result.append(current)
                return
            }
            
            for i in 0..<remaining.count {
                var newCurrent = current
                newCurrent.append(remaining[i])
                var newRemaining = remaining
                newRemaining.remove(at: i)
                permute(current: newCurrent, remaining: newRemaining)
            }
        }
        
        permute(current: [], remaining: options)
        return result
    }
}
```

---

### 2. 更新 MorphObfuscator.swift（高优先级）

**位置**: `ios/App/WireGuardExtension/MorphProtocol/MorphObfuscator.swift`

**需要完全重写**，实现动态函数选择：

```swift
class MorphObfuscator {
    private let key: Int
    private let paddingLength: Int
    private let functionRegistry: FunctionRegistry
    private let totalCombinations: Int
    
    init(key: Int, layer: Int, paddingLength: Int) {
        self.key = key
        self.paddingLength = min(max(paddingLength, 1), 8)
        self.functionRegistry = FunctionRegistry(layer: layer)
        self.totalCombinations = functionRegistry.getFunctionCombos().count
        
        NSLog("🎭 MorphObfuscator: Initialized with \(totalCombinations) combinations")
    }
    
    func obfuscate(_ data: Data) -> Data {
        if data.isEmpty {
            return data
        }
        
        // 1. 生成随机 header (3 bytes)
        var header = Data(count: 3)
        header[0] = UInt8.random(in: 0...255)
        header[1] = UInt8.random(in: 0...255)
        
        // 2. 计算函数组合索引
        let comboIndex = (Int(header[0]) * Int(header[1])) % totalCombinations
        let combo = functionRegistry.getFunctionCombos()[comboIndex]
        
        // 3. 应用函数组合
        var result = data
        let keyArray = generateKeyArray(length: data.count)
        let functions = ObfuscationFunctionRegistry.shared.functions
        
        for funcIndex in combo {
            let function = functions[funcIndex]
            result = function.obfuscation(result, keyArray, function.initor)
        }
        
        // 4. 生成随机填充
        let actualPaddingLength = Int.random(in: 1...paddingLength)
        header[2] = UInt8(actualPaddingLength)
        
        var padding = Data(count: actualPaddingLength)
        for i in 0..<actualPaddingLength {
            padding[i] = UInt8.random(in: 0...255)
        }
        
        // 5. 组合: header + obfuscated data + padding
        var final = Data()
        final.append(header)
        final.append(result)
        final.append(padding)
        
        return final
    }
    
    func deobfuscate(_ data: Data) -> Data {
        // 验证最小长度
        guard data.count >= 4 else {
            NSLog("❌ MorphObfuscator: Data too short for deobfuscation")
            return Data()
        }
        
        // 1. 提取 header
        let header = data[0..<3]
        let paddingLength = Int(header[2])
        
        // 验证填充长度
        guard paddingLength >= 1 && paddingLength <= 8 else {
            NSLog("❌ MorphObfuscator: Invalid padding length: \(paddingLength)")
            return Data()
        }
        
        // 验证总长度
        guard data.count >= 3 + paddingLength else {
            NSLog("❌ MorphObfuscator: Data too short for padding")
            return Data()
        }
        
        // 2. 提取 body (去掉 header 和 padding)
        let bodyLength = data.count - 3 - paddingLength
        let body = data[3..<(3 + bodyLength)]
        
        // 3. 计算函数组合索引
        let comboIndex = (Int(header[0]) * Int(header[1])) % totalCombinations
        let combo = functionRegistry.getFunctionCombos()[comboIndex]
        
        // 4. 反向应用函数组合
        var result = body
        let keyArray = generateKeyArray(length: body.count)
        let functions = ObfuscationFunctionRegistry.shared.functions
        
        for funcIndex in combo.reversed() {
            let function = functions[funcIndex]
            result = function.deobfuscation(result, keyArray, function.initor)
        }
        
        return result
    }
    
    private func generateKeyArray(length: Int) -> Data {
        var keyArray = Data(count: length)
        for i in 0..<length {
            keyArray[i] = UInt8((key + i * 37) % 256)
        }
        return keyArray
    }
}
```

---

### 3. ProtocolTemplates.swift（中优先级）

**位置**: `ios/App/WireGuardExtension/MorphProtocol/ProtocolTemplates.swift`

**功能**: 实现协议伪装

**核心代码**:
```swift
// MARK: - Protocol Template Interface

protocol ProtocolTemplate {
    var templateID: UInt8 { get }
    var name: String { get }
    
    func encapsulate(_ data: Data, clientID: Data) -> Data
    func decapsulate(_ packet: Data) -> Data?
    func extractHeaderID(_ packet: Data) -> Data?
}

// MARK: - QUIC Template

class QuicTemplate: ProtocolTemplate {
    let templateID: UInt8 = 1
    let name = "QUIC"
    
    private var sequenceNumber: UInt32 = 0
    
    func encapsulate(_ data: Data, clientID: Data) -> Data {
        var packet = Data()
        
        // QUIC Short Header
        // [flags(1)] [connectionID(8)] [packetNumber(4)] [payload]
        
        // Flags: 0x40 (short header, fixed bit)
        packet.append(0x40)
        
        // Connection ID: 从 clientID 派生 (取前8字节)
        let connID = clientID.prefix(8)
        packet.append(connID)
        
        // Packet Number: 递增序列号
        var packetNum = sequenceNumber
        packet.append(UInt8((packetNum >> 24) & 0xFF))
        packet.append(UInt8((packetNum >> 16) & 0xFF))
        packet.append(UInt8((packetNum >> 8) & 0xFF))
        packet.append(UInt8(packetNum & 0xFF))
        
        // Payload
        packet.append(data)
        
        sequenceNumber += 1
        
        return packet
    }
    
    func decapsulate(_ packet: Data) -> Data? {
        // 验证最小长度: 1 + 8 + 4 = 13 bytes
        guard packet.count >= 13 else {
            return nil
        }
        
        // 验证 flags
        guard packet[0] == 0x40 else {
            return nil
        }
        
        // 提取 payload (跳过 header)
        return packet[13...]
    }
    
    func extractHeaderID(_ packet: Data) -> Data? {
        guard packet.count >= 9 else {
            return nil
        }
        
        guard packet[0] == 0x40 else {
            return nil
        }
        
        // Connection ID at bytes 1-8
        return packet[1..<9]
    }
}

// MARK: - KCP Template

class KcpTemplate: ProtocolTemplate {
    let templateID: UInt8 = 2
    let name = "KCP"
    
    private var sequenceNumber: UInt32 = 0
    
    func encapsulate(_ data: Data, clientID: Data) -> Data {
        var packet = Data()
        
        // KCP Header
        // [conv(4)] [cmd(1)] [frg(1)] [wnd(2)] [ts(4)] [sn(4)] [una(4)] [payload]
        
        // Conv: 从 clientID 派生 (取前4字节)
        let conv = clientID.prefix(4)
        packet.append(conv)
        
        // Cmd: 0x51 (data packet)
        packet.append(0x51)
        
        // Frg: 0 (no fragmentation)
        packet.append(0x00)
        
        // Wnd: 128 (window size)
        packet.append(0x00)
        packet.append(0x80)
        
        // Ts: timestamp (4 bytes)
        let timestamp = UInt32(Date().timeIntervalSince1970 * 1000)
        packet.append(UInt8((timestamp >> 24) & 0xFF))
        packet.append(UInt8((timestamp >> 16) & 0xFF))
        packet.append(UInt8((timestamp >> 8) & 0xFF))
        packet.append(UInt8(timestamp & 0xFF))
        
        // Sn: sequence number
        var sn = sequenceNumber
        packet.append(UInt8((sn >> 24) & 0xFF))
        packet.append(UInt8((sn >> 16) & 0xFF))
        packet.append(UInt8((sn >> 8) & 0xFF))
        packet.append(UInt8(sn & 0xFF))
        
        // Una: 0
        packet.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        
        // Payload
        packet.append(data)
        
        sequenceNumber += 1
        
        return packet
    }
    
    func decapsulate(_ packet: Data) -> Data? {
        // 验证最小长度: 4 + 1 + 1 + 2 + 4 + 4 + 4 = 20 bytes
        guard packet.count >= 20 else {
            return nil
        }
        
        // 验证 cmd
        guard packet[4] == 0x51 else {
            return nil
        }
        
        // 提取 payload
        return packet[20...]
    }
    
    func extractHeaderID(_ packet: Data) -> Data? {
        guard packet.count >= 4 else {
            return nil
        }
        
        // Conv at bytes 0-3
        return packet[0..<4]
    }
}

// MARK: - Generic Gaming Template

class GenericGamingTemplate: ProtocolTemplate {
    let templateID: UInt8 = 3
    let name = "GenericGaming"
    
    private var sequenceNumber: UInt32 = 0
    
    func encapsulate(_ data: Data, clientID: Data) -> Data {
        var packet = Data()
        
        // Gaming Protocol Header
        // [magic(4)] [sessionID(4)] [sequence(4)] [timestamp(4)] [payload]
        
        // Magic: "GAME"
        packet.append(contentsOf: [0x47, 0x41, 0x4D, 0x45])  // "GAME"
        
        // Session ID: 从 clientID 派生 (取前4字节)
        let sessionID = clientID.prefix(4)
        packet.append(sessionID)
        
        // Sequence
        var seq = sequenceNumber
        packet.append(UInt8((seq >> 24) & 0xFF))
        packet.append(UInt8((seq >> 16) & 0xFF))
        packet.append(UInt8((seq >> 8) & 0xFF))
        packet.append(UInt8(seq & 0xFF))
        
        // Timestamp
        let timestamp = UInt32(Date().timeIntervalSince1970 * 1000)
        packet.append(UInt8((timestamp >> 24) & 0xFF))
        packet.append(UInt8((timestamp >> 16) & 0xFF))
        packet.append(UInt8((timestamp >> 8) & 0xFF))
        packet.append(UInt8(timestamp & 0xFF))
        
        // Payload
        packet.append(data)
        
        sequenceNumber += 1
        
        return packet
    }
    
    func decapsulate(_ packet: Data) -> Data? {
        // 验证最小长度: 4 + 4 + 4 + 4 = 16 bytes
        guard packet.count >= 16 else {
            return nil
        }
        
        // 验证 magic
        guard packet[0] == 0x47 && packet[1] == 0x41 && 
              packet[2] == 0x4D && packet[3] == 0x45 else {
            return nil
        }
        
        // 提取 payload
        return packet[16...]
    }
    
    func extractHeaderID(_ packet: Data) -> Data? {
        guard packet.count >= 8 else {
            return nil
        }
        
        // 验证 magic
        guard packet[0] == 0x47 && packet[1] == 0x41 && 
              packet[2] == 0x4D && packet[3] == 0x45 else {
            return nil
        }
        
        // Session ID at bytes 4-7
        return packet[4..<8]
    }
}

// MARK: - Template Factory

enum TemplateType: UInt8 {
    case quic = 1
    case kcp = 2
    case gaming = 3
}

class TemplateFactory {
    static func createTemplate(_ type: TemplateType) -> ProtocolTemplate {
        switch type {
        case .quic:
            return QuicTemplate()
        case .kcp:
            return KcpTemplate()
        case .gaming:
            return GenericGamingTemplate()
        }
    }
}
```

---

### 4. 更新 MorphUDPClient.swift（高优先级）

**需要集成协议模板**：

```swift
class MorphUDPClient {
    private let encryptor: MorphEncryptor
    private let obfuscator: MorphObfuscator
    private let template: ProtocolTemplate?  // 新增
    private let clientID: Data  // 新增
    
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
                } else {
                    packet = obfuscated
                }
                
                // 4. 发送
                self.connection?.send(content: packet, completion: .contentProcessed { error in
                    if let error = error {
                        NSLog("❌ MorphUDPClient: Send error: \(error)")
                    }
                })
                
            } catch {
                NSLog("❌ MorphUDPClient: Processing error: \(error)")
            }
        }
    }
    
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
}
```

---

### 5. 更新 PacketTunnelProvider.swift

**需要传递模板类型参数**：

```swift
// 在 startTunnel 方法中
if useMorph {
    let templateType: TemplateType?
    if let templateValue = providerConfiguration["morphTemplateType"] as? Int {
        templateType = TemplateType(rawValue: UInt8(templateValue))
    } else {
        templateType = .quic  // 默认使用 QUIC
    }
    
    morphClient = try MorphUDPClient(
        encryptionKey: encryptionKey,
        obfuscationLayer: layerCount,
        paddingLength: paddingLength,
        templateType: templateType
    )
}
```

---

### 6. 更新 React 配置接口

**在 `src/components/TestVpn.tsx` 中添加模板选择**：

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
    morphTemplateType: 1,  // 1=QUIC, 2=KCP, 3=Gaming
};
```

---

## 实施步骤

### 第一阶段：核心功能（必须）

1. ✅ **ObfuscationFunctions.swift** - 已完成
2. ⏳ **FunctionRegistry.swift** - 待实现
3. ⏳ **更新 MorphObfuscator.swift** - 待实现
4. ⏳ **测试混淆功能** - 待实现

### 第二阶段：协议模板（建议）

5. ⏳ **ProtocolTemplates.swift** - 待实现
6. ⏳ **更新 MorphUDPClient.swift** - 待实现
7. ⏳ **测试协议封装** - 待实现

### 第三阶段：集成测试（必须）

8. ⏳ **端到端测试** - 待实现
9. ⏳ **性能测试** - 待实现
10. ⏳ **与服务器对接** - 待实现

---

## 测试用例

### 1. 混淆函数可逆性测试

```swift
func testObfuscationReversibility() {
    let original = Data([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
    let keyArray = Data([0xAA, 0xBB, 0xCC, 0xDD])
    
    let functions = ObfuscationFunctionRegistry.shared.functions
    
    for function in functions {
        let obfuscated = function.obfuscation(original, keyArray, function.initor)
        let deobfuscated = function.deobfuscation(obfuscated, keyArray, function.initor)
        
        XCTAssertEqual(original, deobfuscated, 
                      "Function \(function.name) is not reversible")
    }
}
```

### 2. 动态选择测试

```swift
func testDynamicSelection() {
    let obfuscator = MorphObfuscator(key: 12345, layer: 3, paddingLength: 8)
    let data = Data(repeating: 0x42, count: 100)
    
    var results = Set<Data>()
    for _ in 0..<100 {
        let obfuscated = obfuscator.obfuscate(data)
        results.insert(obfuscated)
    }
    
    // 应该有很多不同的结果（因为 header 是随机的）
    XCTAssertGreaterThan(results.count, 90)
}
```

### 3. 端到端测试

```swift
func testEndToEnd() {
    let obfuscator = MorphObfuscator(key: 12345, layer: 3, paddingLength: 8)
    let original = Data("Hello, MorphProtocol!".utf8)
    
    let obfuscated = obfuscator.obfuscate(original)
    let deobfuscated = obfuscator.deobfuscate(obfuscated)
    
    XCTAssertEqual(original, deobfuscated)
}
```

---

## 性能优化建议

1. **预计算函数组合**
   - 在初始化时计算所有排列
   - 运行时直接查表

2. **使用内联函数**
   - 减少函数调用开销

3. **缓存密钥数组**
   - 避免重复生成

4. **批量处理**
   - 一次处理多个数据包

---

## 下一步

1. **实现 FunctionRegistry.swift**
2. **重写 MorphObfuscator.swift**
3. **测试混淆功能**
4. **实现协议模板**
5. **集成测试**

---

**文档版本**: 1.0  
**创建日期**: 2025-12-13  
**状态**: 实施中
