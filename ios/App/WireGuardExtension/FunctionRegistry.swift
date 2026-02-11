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
    
    /// 每次实例化时创建的 ObfuscationFunctionRegistry（含随机 initializers）
    private let functionRegistry: ObfuscationFunctionRegistry
    
    // 懒加载：只计算当前 layer 需要的排列，避免浪费内存
    private lazy var combos: [[Int]] = {
        return calculatePermutations(n: functions.count, r: obfuscationLayer)
    }()
    
    init(layer: Int) {
        self.obfuscationLayer = min(max(layer, 1), 4)
        self.functionRegistry = ObfuscationFunctionRegistry()
        self.functions = functionRegistry.functions
    }
    
    /// 获取当前层数的函数组合
    func getFunctionCombos() -> [[Int]] {
        return combos
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
    
    /// 获取替换表（用于握手）— 返回实际使用的表
    func getSubstitutionTable() -> [Int] {
        return functionRegistry.substitutionTable.map { Int($0) }
    }
    
    /// 获取随机值（用于握手）— 返回实际使用的值
    func getRandomValue() -> Int {
        return Int(functionRegistry.randomValue)
    }
}
