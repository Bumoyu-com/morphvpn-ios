//
//  MorphEncryptor.swift
//  MorphProtocol Plugin
//
//  MorphProtocol 加密模块 - AES-256-CBC
//

import Foundation
import CommonCrypto

class MorphEncryptor {
    private let key: Data
    private let iv: Data
    
    init(keyString: String) throws {
        NSLog("🔐 MorphEncryptor: Initializing with key string")
        
        // 解析 base64key:base64iv 格式
        let parts = keyString.split(separator: ":")
        guard parts.count == 2 else {
            NSLog("❌ MorphEncryptor: Invalid key format (expected key:iv)")
            throw MorphError.invalidKey
        }
        
        guard let keyData = Data(base64Encoded: String(parts[0])),
              let ivData = Data(base64Encoded: String(parts[1])) else {
            NSLog("❌ MorphEncryptor: Failed to decode base64")
            throw MorphError.invalidKey
        }
        
        NSLog("🔐 MorphEncryptor: Key length: \(keyData.count), IV length: \(ivData.count)")
        
        // 确保密钥长度正确（256位 = 32字节）
        guard keyData.count == 32 else {
            NSLog("❌ MorphEncryptor: Invalid key length (expected 32, got \(keyData.count))")
            throw MorphError.invalidKeyLength
        }
        
        // 确保 IV 长度正确（128位 = 16字节，用于 AES-256-CBC）
        guard ivData.count == 16 else {
            NSLog("❌ MorphEncryptor: Invalid IV length (expected 16, got \(ivData.count))")
            throw MorphError.invalidNonceLength
        }
        
        self.key = keyData
        self.iv = ivData
        
        NSLog("✅ MorphEncryptor: Initialized successfully")
    }
    
    func encrypt(_ data: Data) throws -> Data {
        return try performCrypt(data: data, operation: CCOperation(kCCEncrypt))
    }
    
    func decrypt(_ data: Data) throws -> Data {
        return try performCrypt(data: data, operation: CCOperation(kCCDecrypt))
    }
    
    private func performCrypt(data: Data, operation: CCOperation) throws -> Data {
        let dataLength = data.count
        let bufferSize = dataLength + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)
        var numBytesProcessed: size_t = 0
        
        let cryptStatus = key.withUnsafeBytes { keyBytes in
            iv.withUnsafeBytes { ivBytes in
                data.withUnsafeBytes { dataBytes in
                    buffer.withUnsafeMutableBytes { bufferBytes in
                        CCCrypt(
                            operation,
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, key.count,
                            ivBytes.baseAddress,
                            dataBytes.baseAddress, dataLength,
                            bufferBytes.baseAddress, bufferSize,
                            &numBytesProcessed
                        )
                    }
                }
            }
        }
        
        guard cryptStatus == kCCSuccess else {
            NSLog("❌ MorphEncryptor: Crypt operation failed with status: \(cryptStatus)")
            throw operation == kCCEncrypt ? MorphError.encryptionFailed : MorphError.decryptionFailed
        }
        
        buffer.count = numBytesProcessed
        return buffer
    }
}
