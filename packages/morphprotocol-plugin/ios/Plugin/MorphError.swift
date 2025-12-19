//
//  MorphError.swift
//  MorphProtocol Plugin
//
//  MorphProtocol 错误定义
//

import Foundation

enum MorphError: Error {
    case invalidKey
    case invalidKeyLength
    case invalidNonceLength
    case encryptionFailed
    case decryptionFailed
    case connectionFailed
    case sendFailed
    case receiveFailed
    case invalidConfiguration
    case notConnected
}
