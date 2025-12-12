//
//  MorphEncryptor.swift
//  WireGuardExtension
//
//  MorphProtocol 加密模块
//

import Foundation
import CryptoKit

class MorphEncryptor {
    private let key: SymmetricKey
    private var nonce: AES.GCM.Nonce
    
    init(keyString: String) throws {
        // 解析 base64key:base64iv 格式
        let parts = keyString.split(separator: ":")
        guard parts.count == 2 else {
            throw MorphError.invalidKey
        }
        
        guard let keyData = Data(base64Encoded: String(parts[0])),
              let nonceData = Data(base64Encoded: String(parts[1])) else {
            throw MorphError.invalidKey
        }
        
        // 确保密钥长度正确（256位 = 32字节）
        guard keyData.count == 32 else {
            throw MorphError.invalidKeyLength
        }
        
        // 确保 nonce 长度正确（96位 = 12字节）
        guard nonceData.count == 12 else {
            throw MorphError.invalidNonceLength
        }
        
        self.key = SymmetricKey(data: keyData)
        self.nonce = try AES.GCM.Nonce(data: nonceData)
    }
    
    func encrypt(_ data: Data) throws -> Data {
        do {
            let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
            guard let combined = sealedBox.combined else {
                throw MorphError.encryptionFailed
            }
            return combined
        } catch {
            NSLog("❌ MorphEncryptor: Encryption failed: \(error)")
            throw MorphError.encryptionFailed
        }
    }
    
    func decrypt(_ data: Data) throws -> Data {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decrypted = try AES.GCM.open(sealedBox, using: key)
            return decrypted
        } catch {
            NSLog("❌ MorphEncryptor: Decryption failed: \(error)")
            throw MorphError.decryptionFailed
        }
    }
}

enum MorphError: Error {
    case invalidKey
    case invalidKeyLength
    case invalidNonceLength
    case encryptionFailed
    case decryptionFailed
    case connectionFailed
    case sendFailed
    case receiveFailed
}
