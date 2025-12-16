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
        var result = Data(count: data.count)
        for i in 0..<data.count {
            let key = keyArray[i % keyArray.count]
            // XOR with key
            var byte = data[i] ^ key
            // Rotate left by 3 bits
            byte = ((byte << 3) | (byte >> 5)) & 0xFF
            result[i] = byte
        }
        return result
    }
    
    static func deobfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        var result = Data(count: data.count)
        for i in 0..<data.count {
            let key = keyArray[i % keyArray.count]
            var byte = data[i]
            // Rotate right by 3 bits
            byte = ((byte >> 3) | (byte << 5)) & 0xFF
            // XOR with key
            byte = byte ^ key
            result[i] = byte
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
/// 循环移位混淆
struct CircularShiftObfuscation {
    static func obfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        let count = data.count
        if count == 0 {
            return data
        }
        
        // Shift amount based on first key byte
        let shift = Int(keyArray[0]) % count
        
        var result = Data(count: count)
        for i in 0..<count {
            result[(i + shift) % count] = data[i]
        }
        
        return result
    }
    
    static func deobfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        let count = data.count
        if count == 0 {
            return data
        }
        
        // Reverse shift
        let shift = Int(keyArray[0]) % count
        
        var result = Data(count: count)
        for i in 0..<count {
            result[i] = data[(i + shift) % count]
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
/// 位移操作
struct ShiftBits {
    static func obfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        var result = Data(count: data.count)
        for i in 0..<data.count {
            let shift = Int(keyArray[i % keyArray.count]) % 8
            let byte = data[i]
            // Left shift with wrap
            result[i] = ((byte << shift) | (byte >> (8 - shift))) & 0xFF
        }
        return result
    }
    
    static func deobfuscation(_ data: Data, _ keyArray: Data, _ initor: Any?) -> Data {
        var result = Data(count: data.count)
        for i in 0..<data.count {
            let shift = Int(keyArray[i % keyArray.count]) % 8
            let byte = data[i]
            // Right shift with wrap
            result[i] = ((byte >> shift) | (byte << (8 - shift))) & 0xFF
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

class ObfuscationFunctionRegistry {
    static let shared = ObfuscationFunctionRegistry()
    
    private(set) var functions: [FunctionPair] = []
    
    private init() {
        registerAllFunctions()
    }
    
    private func registerAllFunctions() {
        // Register all 11 obfuscation functions
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
                initor: generateSubstitutionTable(),
                index: 9,
                name: "Substitution"
            ),
            FunctionPair(
                obfuscation: AddRandomValue.obfuscation,
                deobfuscation: AddRandomValue.deobfuscation,
                initor: UInt8(42),  // Fixed random value for reversibility
                index: 10,
                name: "AddRandomValue"
            )
        ]
    }
    
    private func generateSubstitutionTable() -> [UInt8] {
        // Generate a fixed substitution table (S-box)
        // Using a simple permutation for demonstration
        var table = [UInt8](0...255)
        
        // Fisher-Yates shuffle with fixed seed for reproducibility
        var rng = SeededRandom(seed: 12345)
        for i in (1..<256).reversed() {
            let j = rng.next() % (i + 1)
            table.swapAt(i, j)
        }
        
        return table
    }
}

// MARK: - Seeded Random Number Generator

struct SeededRandom {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed
    }
    
    mutating func next() -> Int {
        // Linear congruential generator
        state = (state &* 1103515245 &+ 12345) & 0x7FFFFFFF
        return Int(state)
    }
}
