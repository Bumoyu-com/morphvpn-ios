//
//  MorphObfuscator.swift
//  WireGuardExtension
//
//  MorphProtocol 混淆模块 - 完整实现动态函数选择
//

import Foundation

class MorphObfuscator {
    let key: Int  // 改为 public，用于握手
    let layer: Int  // 添加 layer 属性
    let paddingLength: Int  // 改为 public，用于握手
    private let functionRegistry: FunctionRegistry
    private let totalCombinations: Int
    
    init(key: Int, layer: Int, paddingLength: Int) {
        self.key = key
        self.layer = layer
        self.paddingLength = min(max(paddingLength, 1), 16)
        self.functionRegistry = FunctionRegistry(layer: layer)
        self.totalCombinations = functionRegistry.getTotalCombinations()
        
        NSLog("🎭 MorphObfuscator: Initialized")
        NSLog("   Key: \(key)")
        NSLog("   Layer: \(layer)")
        NSLog("   Padding: \(paddingLength)")
        NSLog("   Total Combinations: \(totalCombinations)")
    }
    
    /// 混淆数据
    /// 格式: [header(3)] [obfuscated data] [padding(1-paddingLength)]
    func obfuscate(_ data: Data) -> Data {
        if data.isEmpty {
            return data
        }
        
        // 1. 生成随机 header (3 bytes)
        var header = Data(count: 3)
        header[0] = UInt8.random(in: 0...255)
        header[1] = UInt8.random(in: 0...255)
        
        // 2. 计算函数组合索引
        let comboIndex = functionRegistry.calculateComboIndex(
            header0: header[0],
            header1: header[1]
        )
        
        guard let combo = functionRegistry.getCombo(at: comboIndex) else {
            NSLog("❌ MorphObfuscator: Failed to get combo at index \(comboIndex)")
            return data
        }
        
        // 3. 应用函数组合
        var result = data
        let keyArray = generateKeyArray(length: data.count)
        
        for funcIndex in combo {
            guard let function = functionRegistry.getFunction(at: funcIndex) else {
                NSLog("❌ MorphObfuscator: Failed to get function at index \(funcIndex)")
                continue
            }
            
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
    
    /// 解混淆数据
    func deobfuscate(_ data: Data) -> Data {
        // 验证最小长度: header(3) + at least 1 byte data + padding(1)
        guard data.count >= 5 else {
            NSLog("❌ MorphObfuscator: Data too short for deobfuscation (length: \(data.count))")
            return Data()
        }
        
        // 1. 提取 header
        let header = data[0..<3]
        let paddingLength = Int(header[2])
        
        // 验证填充长度
        guard paddingLength >= 1 && paddingLength <= 16 else {
            NSLog("❌ MorphObfuscator: Invalid padding length: \(paddingLength)")
            return Data()
        }
        
        // 验证总长度
        guard data.count >= 3 + paddingLength else {
            NSLog("❌ MorphObfuscator: Data too short for padding (length: \(data.count), padding: \(paddingLength))")
            return Data()
        }
        
        // 2. 提取 body (去掉 header 和 padding)
        let bodyLength = data.count - 3 - paddingLength
        guard bodyLength > 0 else {
            NSLog("❌ MorphObfuscator: No data after removing header and padding")
            return Data()
        }
        
        let body = data[3..<(3 + bodyLength)]
        
        // 3. 计算函数组合索引
        let comboIndex = functionRegistry.calculateComboIndex(
            header0: header[0],
            header1: header[1]
        )
        
        guard let combo = functionRegistry.getCombo(at: comboIndex) else {
            NSLog("❌ MorphObfuscator: Failed to get combo at index \(comboIndex)")
            return Data()
        }
        
        // 4. 反向应用函数组合
        var result = body
        let keyArray = generateKeyArray(length: body.count)
        
        for funcIndex in combo.reversed() {
            guard let function = functionRegistry.getFunction(at: funcIndex) else {
                NSLog("❌ MorphObfuscator: Failed to get function at index \(funcIndex)")
                continue
            }
            
            result = function.deobfuscation(result, keyArray, function.initor)
        }
        
        return result
    }
    
    /// 生成密钥数组
    private func generateKeyArray(length: Int) -> Data {
        var keyArray = Data(count: length)
        for i in 0..<length {
            keyArray[i] = UInt8((key + i * 37) % 256)
        }
        return keyArray
    }
    
    /// 打印统计信息
    func printStatistics() {
        NSLog("🎭 MorphObfuscator Statistics:")
        NSLog("   Key: \(key)")
        NSLog("   Padding Length: 1-\(paddingLength)")
        NSLog("   Total Combinations: \(totalCombinations)")
        functionRegistry.printStatistics()
    }
}

// MARK: - Testing Helpers

extension MorphObfuscator {
    /// 测试可逆性
    func testReversibility(testData: Data) -> Bool {
        let obfuscated = obfuscate(testData)
        let deobfuscated = deobfuscate(obfuscated)
        
        let isReversible = testData == deobfuscated
        
        if isReversible {
            NSLog("✅ MorphObfuscator: Reversibility test passed")
        } else {
            NSLog("❌ MorphObfuscator: Reversibility test failed")
            NSLog("   Original length: \(testData.count)")
            NSLog("   Obfuscated length: \(obfuscated.count)")
            NSLog("   Deobfuscated length: \(deobfuscated.count)")
        }
        
        return isReversible
    }
    
    /// 测试动态性（多次混淆同一数据应产生不同结果）
    func testDynamism(testData: Data, iterations: Int = 10) -> Bool {
        var results = Set<Data>()
        
        for _ in 0..<iterations {
            let obfuscated = obfuscate(testData)
            results.insert(obfuscated)
        }
        
        let uniqueCount = results.count
        let isDynamic = uniqueCount >= iterations * 8 / 10  // 至少80%不同
        
        if isDynamic {
            NSLog("✅ MorphObfuscator: Dynamism test passed (\(uniqueCount)/\(iterations) unique)")
        } else {
            NSLog("⚠️ MorphObfuscator: Dynamism test warning (\(uniqueCount)/\(iterations) unique)")
        }
        
        return isDynamic
    }
    
    // MARK: - 握手参数获取
    
    /// 获取替换表（用于握手）
    func getSubstitutionTable() -> [Int] {
        return functionRegistry.getSubstitutionTable()
    }
    
    /// 获取随机值（用于握手）
    func getRandomValue() -> Int {
        return functionRegistry.getRandomValue()
    }
}
