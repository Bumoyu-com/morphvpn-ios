//
//  MorphObfuscator.swift
//  WireGuardExtension
//
//  MorphProtocol 混淆模块
//

import Foundation

class MorphObfuscator {
    private let layer: Int
    private let paddingLength: Int
    
    init(layer: Int = 3, paddingLength: Int = 8) {
        self.layer = min(max(layer, 1), 4)
        self.paddingLength = min(max(paddingLength, 1), 16)
    }
    
    func obfuscate(_ data: Data) -> Data {
        var result = data
        
        // 应用多层混淆
        for i in 0..<layer {
            result = applyObfuscationLayer(result, layerIndex: i)
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
        for i in (0..<layer).reversed() {
            result = removeObfuscationLayer(result, layerIndex: i)
        }
        
        return result
    }
    
    private func applyObfuscationLayer(_ data: Data, layerIndex: Int) -> Data {
        var result = Data(count: data.count)
        
        // 根据层级使用不同的混淆掩码
        let masks: [UInt8] = [0xAA, 0x55, 0x33, 0xCC]
        let mask = masks[layerIndex % masks.count]
        
        for i in 0..<data.count {
            // XOR 混淆
            result[i] = data[i] ^ mask
            
            // 位旋转
            result[i] = rotateLeft(result[i], by: UInt8(layerIndex + 1))
        }
        
        return result
    }
    
    private func removeObfuscationLayer(_ data: Data, layerIndex: Int) -> Data {
        var result = Data(count: data.count)
        
        let masks: [UInt8] = [0xAA, 0x55, 0x33, 0xCC]
        let mask = masks[layerIndex % masks.count]
        
        for i in 0..<data.count {
            // 反向位旋转
            result[i] = rotateRight(data[i], by: UInt8(layerIndex + 1))
            
            // XOR 解混淆（XOR 是对称的）
            result[i] = result[i] ^ mask
        }
        
        return result
    }
    
    private func addPadding(_ data: Data) -> Data {
        var result = data
        
        // 添加随机填充
        var padding = Data(count: paddingLength)
        for i in 0..<paddingLength {
            padding[i] = UInt8.random(in: 0...255)
        }
        
        result.append(padding)
        return result
    }
    
    private func removePadding(_ data: Data) -> Data {
        guard data.count > paddingLength else {
            return data
        }
        return data.prefix(data.count - paddingLength)
    }
    
    // 位旋转辅助函数
    private func rotateLeft(_ value: UInt8, by shift: UInt8) -> UInt8 {
        let shift = shift % 8
        return (value << shift) | (value >> (8 - shift))
    }
    
    private func rotateRight(_ value: UInt8, by shift: UInt8) -> UInt8 {
        let shift = shift % 8
        return (value >> shift) | (value << (8 - shift))
    }
}
