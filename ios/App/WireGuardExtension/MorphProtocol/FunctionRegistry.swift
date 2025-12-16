//
//  FunctionRegistry.swift
//  WireGuardExtension
//
//  MorphProtocol 函数注册表 - 管理函数组合和排列
//

import Foundation

class FunctionRegistry {
    private let obfuscationLayer: Int
    private let functions: [FunctionPair]
    
    // 预计算的函数组合（排列）
    private var combos1: [[Int]] = []
    private var combos2: [[Int]] = []
    private var combos3: [[Int]] = []
    private var combos4: [[Int]] = []
    
    init(layer: Int) {
        self.obfuscationLayer = min(max(layer, 1), 4)
        self.functions = ObfuscationFunctionRegistry.shared.functions
        
        NSLog("🎭 FunctionRegistry: Initializing with layer=\(obfuscationLayer)")
        
        // 预计算所有排列
        let startTime = Date()
        
        combos1 = calculatePermutations(n: functions.count, r: 1)
        combos2 = calculatePermutations(n: functions.count, r: 2)
        combos3 = calculatePermutations(n: functions.count, r: 3)
        combos4 = calculatePermutations(n: functions.count, r: 4)
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        NSLog("🎭 FunctionRegistry: Precomputed combinations:")
        NSLog("   Layer 1: \(combos1.count) combinations")
        NSLog("   Layer 2: \(combos2.count) combinations")
        NSLog("   Layer 3: \(combos3.count) combinations")
        NSLog("   Layer 4: \(combos4.count) combinations")
        NSLog("   Time: \(String(format: "%.3f", elapsed))s")
    }
    
    /// 获取当前层数的函数组合
    func getFunctionCombos() -> [[Int]] {
        switch obfuscationLayer {
        case 1: return combos1
        case 2: return combos2
        case 3: return combos3
        case 4: return combos4
        default: return combos3
        }
    }
    
    /// 获取函数对象
    func getFunction(at index: Int) -> FunctionPair? {
        guard index >= 0 && index < functions.count else {
            return nil
        }
        return functions[index]
    }
    
    /// 获取总组合数
    func getTotalCombinations() -> Int {
        return getFunctionCombos().count
    }
    
    /// 计算排列 P(n, r) = n!/(n-r)!
    /// 返回所有可能的排列组合
    private func calculatePermutations(n: Int, r: Int) -> [[Int]] {
        guard r > 0 && r <= n else {
            return []
        }
        
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
    
    /// 根据 header 计算函数组合索引
    func calculateComboIndex(header0: UInt8, header1: UInt8) -> Int {
        let totalCombos = getTotalCombinations()
        guard totalCombos > 0 else {
            return 0
        }
        
        let index = (Int(header0) * Int(header1)) % totalCombos
        return index
    }
    
    /// 获取指定索引的函数组合
    func getCombo(at index: Int) -> [Int]? {
        let combos = getFunctionCombos()
        guard index >= 0 && index < combos.count else {
            return nil
        }
        return combos[index]
    }
    
    /// 打印统计信息
    func printStatistics() {
        NSLog("🎭 FunctionRegistry Statistics:")
        NSLog("   Obfuscation Layer: \(obfuscationLayer)")
        NSLog("   Total Functions: \(functions.count)")
        NSLog("   Total Combinations: \(getTotalCombinations())")
        NSLog("   Function Names:")
        for (index, function) in functions.enumerated() {
            NSLog("     [\(index)] \(function.name)")
        }
    }
}

// MARK: - Helper Extensions

extension FunctionRegistry {
    /// 验证函数组合的唯一性
    func validateUniqueness() -> Bool {
        let combos = getFunctionCombos()
        let uniqueCombos = Set(combos.map { $0.description })
        
        let isUnique = uniqueCombos.count == combos.count
        
        if isUnique {
            NSLog("✅ FunctionRegistry: All combinations are unique")
        } else {
            NSLog("⚠️ FunctionRegistry: Found duplicate combinations!")
        }
        
        return isUnique
    }
    
    /// 获取随机函数组合（用于测试）
    func getRandomCombo() -> [Int] {
        let combos = getFunctionCombos()
        guard !combos.isEmpty else {
            return []
        }
        
        let randomIndex = Int.random(in: 0..<combos.count)
        return combos[randomIndex]
    }
}
