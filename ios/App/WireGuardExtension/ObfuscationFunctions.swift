//
//  ObfuscationFunctions.swift
//  WireGuardExtension
//
//  MorphProtocol 混淆函数库 - 完整实现11种可逆混淆函数
//

import Foundation

// MARK: - Function Pair Structure

struct FunctionPair {
    let obfuscation: (Data, Data, Any?) -> Data
    let deobfuscation: (Data, Data, Any?) -> Data
    let initor: Any?
    let index: Int
    let name: String
}

// MARK: - Obfuscation Functions

/// 1. Bitwise Rotation and XOR
/// 对每个字节进行位旋转和XOR操作
struct BitwiseRotationAndXOR {
    static func obfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        let length = data.count
        var result = Data(count: length)
        for i in 0..<length {
            let shift = (i % 8) + 1
            let inputValue = Int(data[i])
            // Rotate left by shift bits
            let rotated = ((inputValue << shift) | (inputValue >> (8 - shift))) & 0xFF
            // XOR with key at index (i + length - 1) % length
            let keyIndex = (i + length - 1) % length
            result[i] = UInt8(rotated ^ Int(keyArray[keyIndex % keyArray.count]))
        }
        return result
    }
    
    static func deobfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        let length = data.count
        var result = Data(count: length)
        for i in 0..<length {
            let shift = (i % 8) + 1
            let keyIndex = (i + length - 1) % length
            // XOR with key first
            let xored = Int(data[i]) ^ Int(keyArray[keyIndex % keyArray.count])
            // Rotate right by shift bits
            result[i] = UInt8(((xored >> shift) | (xored << (8 - shift))) & 0xFF)
        }
        return result
    }
}

/// 2. Swap Neighboring Bytes
/// 交换相邻的字节对
struct SwapNeighboringBytes {
    static func obfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        var result = Data(data)
        let count = data.count
        
        // Swap pairs of bytes
        for i in stride(from: 0, to: count - 1, by: 2) {
            result.swapAt(i, i + 1)
        }
        
        return result
    }
    
    static func deobfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        // Swapping is reversible by swapping again
        return obfuscation(data, keyArray, initor)
    }
}

/// 3. Reverse Buffer
/// 反转整个缓冲区
struct ReverseBuffer {
    static func obfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        return Data(data.reversed())
    }
    
    static func deobfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        // Reversing is reversible by reversing again
        return Data(data.reversed())
    }
}

/// 4. Divide and Swap
/// 将缓冲区分成两半并交换
struct DivideAndSwap {
    static func obfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        let count = data.count
        if count < 2 {
            return data
        }
        
        let mid = count / 2
        let firstHalf = data[0..<mid]
        let secondHalf = data[mid..<count]
        
        var result = Data()
        result.append(secondHalf)
        result.append(firstHalf)
        
        return result
    }
    
    static func deobfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        // Swapping halves is reversible by swapping again
        return obfuscation(data, keyArray, initor)
    }
}

/// 5. Circular Shift Obfuscation
/// 每字节左移 1 bit（与 Android 对齐）
struct CircularShiftObfuscation {
    static func obfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        var result = Data(count: data.count)
        for i in 0..<data.count {
            let v = Int(data[i])
            result[i] = UInt8(((v << 1) | (v >> 7)) & 0xFF)
        }
        return result
    }
    
    static func deobfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        var result = Data(count: data.count)
        for i in 0..<data.count {
            let v = Int(data[i])
            result[i] = UInt8(((v >> 1) | (v << 7)) & 0xFF)
        }
        return result
    }
}

/// 6. XOR with Key
/// 使用密钥进行XOR操作
struct XorWithKey {
    static func obfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        var result = Data(count: data.count)
        for i in 0..<data.count {
            result[i] = data[i] ^ keyArray[i % keyArray.count]
        }
        return result
    }
    
    static func deobfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        // XOR is reversible by XORing again
        return obfuscation(data, keyArray, initor)
    }
}

/// 7. Bitwise NOT
/// 按位取反
struct BitwiseNOT {
    static func obfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        var result = Data(count: data.count)
        for i in 0..<data.count {
            result[i] = ~data[i]
        }
        return result
    }
    
    static func deobfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        // NOT is reversible by NOTing again
        return obfuscation(data, keyArray, initor)
    }
}

/// 8. Reverse Bits
/// 反转每个字节的位
struct ReverseBits {
    static func reverseByte(_ byte: UInt8) -> UInt8 {
        var result: UInt8 = 0
        var b = byte
        for _ in 0..<8 {
            result = (result << 1) | (b & 1)
            b >>= 1
        }
        return result
    }
    
    static func obfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        var result = Data(count: data.count)
        for i in 0..<data.count {
            result[i] = reverseByte(data[i])
        }
        return result
    }
    
    static func deobfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        // Reversing bits is reversible by reversing again
        return obfuscation(data, keyArray, initor)
    }
}

/// 9. Shift Bits
/// 固定左移 2 bit（与 Android 对齐）
struct ShiftBits {
    static func obfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        var result = Data(count: data.count)
        for i in 0..<data.count {
            let v = Int(data[i])
            result[i] = UInt8(((v << 2) | (v >> 6)) & 0xFF)
        }
        return result
    }
    
    static func deobfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        var result = Data(count: data.count)
        for i in 0..<data.count {
            let v = Int(data[i])
            result[i] = UInt8(((v >> 2) | (v << 6)) & 0xFF)
        }
        return result
    }
}

/// 10. Substitution
/// 字节替换（使用替换表）
struct Substitution {
    static func obfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        guard let table = initor as? [UInt8], table.count == 256 else {
            // Fallback: simple XOR if no table provided
            return XorWithKey.obfuscation(data, keyArray, nil)
        }
        
        var result = Data(count: data.count)
        for i in 0..<data.count {
            result[i] = table[Int(data[i])]
        }
        return result
    }
    
    static func deobfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        guard let table = initor as? [UInt8], table.count == 256 else {
            // Fallback: simple XOR if no table provided
            return XorWithKey.deobfuscation(data, keyArray, nil)
        }
        
        // Create reverse lookup table
        var reverseTable = [UInt8](repeating: 0, count: 256)
        for i in 0..<256 {
            reverseTable[Int(table[i])] = UInt8(i)
        }
        
        var result = Data(count: data.count)
        for i in 0..<data.count {
            result[i] = reverseTable[Int(data[i])]
        }
        return result
    }
}

/// 11. Add Random Value
/// 添加随机值（使用固定的随机值以保证可逆）
struct AddRandomValue {
    static func obfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        guard let randomValue = initor as? UInt8 else {
            // Fallback: use first key byte
            let value = keyArray.count > 0 ? keyArray[0] : 0
            return addValue(data, value)
        }
        
        return addValue(data, randomValue)
    }
    
    static func deobfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        guard let randomValue = initor as? UInt8 else {
            // Fallback: use first key byte
            let value = keyArray.count > 0 ? keyArray[0] : 0
            return subtractValue(data, value)
        }
        
        return subtractValue(data, randomValue)
    }
    
    private static func addValue(_ data: Data, _ value: UInt8) -> Data {
        var result = Data(count: data.count)
        for i in 0..<data.count {
            result[i] = data[i] &+ value  // Wrapping addition
        }
        return result
    }
    
    private static func subtractValue(_ data: Data, _ value: UInt8) -> Data {
        var result = Data(count: data.count)
        for i in 0..<data.count {
            result[i] = data[i] &- value  // Wrapping subtraction
        }
        return result
    }
}

// MARK: - Function Registry

/// 每次实例化时随机生成 substitutionTable 和 randomValue，
/// 与 Android FunctionInitializer.generateInitializers() 对齐。
/// 不再使用单例，由 FunctionRegistry 持有。
class ObfuscationFunctionRegistry {
    private(set) var functions: [FunctionPair] = []
    
    /// 运行时随机生成的 substitutionTable（256 字节），用于握手发送
    private(set) var substitutionTable: [UInt8] = []
    /// 运行时随机生成的 randomValue（0-255），用于握手发送
    private(set) var randomValue: UInt8 = 0
    
    init() {
        // 运行时随机生成 initializers（与 Android FunctionInitializer 对齐）
        substitutionTable = ObfuscationFunctionRegistry.generateRandomSubstitutionTable()
        randomValue = UInt8.random(in: 0...255)
        
        registerAllFunctions()
    }
    
    /// 使用外部传入的参数初始化（Extension 进程复用 App 进程握手时的参数）
    init(substitutionTable: [UInt8], randomValue: UInt8) {
        self.substitutionTable = substitutionTable
        self.randomValue = randomValue
        
        registerAllFunctions()
    }
    
    private func registerAllFunctions() {
        functions = [
            FunctionPair(
                obfuscation: BitwiseRotationAndXOR.obfuscation,
                deobfuscation: BitwiseRotationAndXOR.deobfuscation,
                initor: nil,
                index: 0,
                name: "BitwiseRotationAndXOR"
            ),
            FunctionPair(
                obfuscation: SwapNeighboringBytes.obfuscation,
                deobfuscation: SwapNeighboringBytes.deobfuscation,
                initor: nil,
                index: 1,
                name: "SwapNeighboringBytes"
            ),
            FunctionPair(
                obfuscation: ReverseBuffer.obfuscation,
                deobfuscation: ReverseBuffer.deobfuscation,
                initor: nil,
                index: 2,
                name: "ReverseBuffer"
            ),
            FunctionPair(
                obfuscation: DivideAndSwap.obfuscation,
                deobfuscation: DivideAndSwap.deobfuscation,
                initor: nil,
                index: 3,
                name: "DivideAndSwap"
            ),
            FunctionPair(
                obfuscation: CircularShiftObfuscation.obfuscation,
                deobfuscation: CircularShiftObfuscation.deobfuscation,
                initor: nil,
                index: 4,
                name: "CircularShiftObfuscation"
            ),
            FunctionPair(
                obfuscation: XorWithKey.obfuscation,
                deobfuscation: XorWithKey.deobfuscation,
                initor: nil,
                index: 5,
                name: "XorWithKey"
            ),
            FunctionPair(
                obfuscation: BitwiseNOT.obfuscation,
                deobfuscation: BitwiseNOT.deobfuscation,
                initor: nil,
                index: 6,
                name: "BitwiseNOT"
            ),
            FunctionPair(
                obfuscation: ReverseBits.obfuscation,
                deobfuscation: ReverseBits.deobfuscation,
                initor: nil,
                index: 7,
                name: "ReverseBits"
            ),
            FunctionPair(
                obfuscation: ShiftBits.obfuscation,
                deobfuscation: ShiftBits.deobfuscation,
                initor: nil,
                index: 8,
                name: "ShiftBits"
            ),
            FunctionPair(
                obfuscation: Substitution.obfuscation,
                deobfuscation: Substitution.deobfuscation,
                initor: substitutionTable,  // 运行时随机生成的表
                index: 9,
                name: "Substitution"
            ),
            FunctionPair(
                obfuscation: AddRandomValue.obfuscation,
                deobfuscation: AddRandomValue.deobfuscation,
                initor: randomValue,  // 运行时随机生成的值
                index: 10,
                name: "AddRandomValue"
            )
        ]
    }
    
    /// Fisher-Yates shuffle 生成随机 256 字节替换表
    private static func generateRandomSubstitutionTable() -> [UInt8] {
        var table = [UInt8](0...255)
        for i in (1..<256).reversed() {
            let j = Int.random(in: 0...i)
            table.swapAt(i, j)
        }
        return table
    }
}
