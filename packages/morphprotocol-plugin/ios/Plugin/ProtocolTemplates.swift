//
//  ProtocolTemplates.swift
//  WireGuardExtension
//
//  MorphProtocol 协议模板 - 实现流量伪装
//

import Foundation

// MARK: - Protocol Template Interface

protocol ProtocolTemplate {
    var id: UInt8 { get }  // 改名为 id，与服务端一致
    var templateID: UInt8 { get }  // 保留兼容性
    var name: String { get }
    
    func encapsulate(_ data: Data, clientID: Data) -> Data
    func decapsulate(_ packet: Data) -> Data?
    func extractHeaderID(_ packet: Data) -> Data?
    func getParams() -> [String: Any]  // 新增：获取模板参数
}

// MARK: - QUIC Template

/// QUIC 协议模板
/// 模拟 QUIC 短头部格式
/// 与服务端保持一致: Header: [flags(1)] [connectionID(8)] [packetNumber(2)] = 11 bytes
class QuicTemplate: ProtocolTemplate {
    let templateID: UInt8 = 1
    let name = "QUIC"
    
    private var sequenceNumber: UInt16 = 0
    private let lock = NSLock()
    
    /// 封装数据为 QUIC 格式
    /// Header: [flags(1)] [connectionID(8)] [packetNumber(2)] [payload]
    /// Total header: 11 bytes (与服务端一致)
    func encapsulate(_ data: Data, clientID: Data) -> Data {
        var packet = Data()
        
        // Flags: 0x40-0x4f (QUIC short header, various spin bits)
        packet.append(0x40 | UInt8(arc4random_uniform(16)))
        
        // Connection ID: 从 clientID 派生 (取前8字节，不足则填充)
        var connID = clientID.prefix(8)
        while connID.count < 8 {
            connID.append(0x00)
        }
        packet.append(connID)
        
        // Packet Number: 递增序列号 (2 bytes, big-endian) - 与服务端一致
        lock.lock()
        let packetNum = sequenceNumber
        sequenceNumber = sequenceNumber &+ 1
        lock.unlock()
        
        packet.append(UInt8((packetNum >> 8) & 0xFF))
        packet.append(UInt8(packetNum & 0xFF))
        
        // Payload
        packet.append(data)
        
        return packet
    }
    
    /// 解封装 QUIC 数据包
    func decapsulate(_ packet: Data) -> Data? {
        // 验证最小长度: 1 + 8 + 2 = 11 bytes
        guard packet.count >= 11 else {
            return nil
        }
        
        // 验证 flags (应该是 0x40-0x4f)
        guard (packet[0] & 0xF0) == 0x40 else {
            return nil
        }
        
        // 提取 payload (跳过 11 字节 header)
        return Data(packet[11...])
    }
    
    /// 提取 header 中的客户端 ID
    func extractHeaderID(_ packet: Data) -> Data? {
        guard packet.count >= 9 else {
            return nil
        }
        
        guard (packet[0] & 0xF0) == 0x40 else {
            return nil
        }
        
        // Connection ID at bytes 1-8
        return Data(packet[1..<9])
    }
}

// MARK: - KCP Template

/// KCP 协议模板
/// 模拟 KCP 协议头部格式
/// 与服务端保持一致: Header: [conv(4)] [cmd(1)] [frg(1)] [wnd(2)] [ts(4)] [sn(4)] [una(4)] [len(4)] = 24 bytes
class KcpTemplate: ProtocolTemplate {
    let templateID: UInt8 = 2
    let name = "KCP"
    
    private var sequenceNumber: UInt32 = 0
    private let lock = NSLock()
    
    /// 封装数据为 KCP 格式
    /// Header: [conv(4)] [cmd(1)] [frg(1)] [wnd(2)] [ts(4)] [sn(4)] [una(4)] [len(4)] [payload]
    /// Total header: 24 bytes
    /// 所有多字节字段使用 big-endian（与 Android ByteBuffer 默认行为对齐）
    func encapsulate(_ data: Data, clientID: Data) -> Data {
        var packet = Data(capacity: 24 + data.count)
        
        // Conv: 从 clientID 派生 (取前4字节)
        var conv = clientID.prefix(4)
        while conv.count < 4 {
            conv.append(0x00)
        }
        packet.append(conv)
        
        // Cmd: 0x51 (PSH - data packet)
        packet.append(0x51)
        
        // Frg: 0 (no fragmentation)
        packet.append(0x00)
        
        // Wnd: 256 (window size, 2 bytes, big-endian)
        packet.append(UInt8((256 >> 8) & 0xFF))  // 0x01
        packet.append(UInt8(256 & 0xFF))          // 0x00
        
        // Ts: timestamp (4 bytes, big-endian)
        let timestampMs = Date().timeIntervalSince1970 * 1000
        let timestamp = UInt32(truncatingIfNeeded: UInt64(timestampMs))
        packet.append(UInt8((timestamp >> 24) & 0xFF))
        packet.append(UInt8((timestamp >> 16) & 0xFF))
        packet.append(UInt8((timestamp >> 8) & 0xFF))
        packet.append(UInt8(timestamp & 0xFF))
        
        // Sn: sequence number (4 bytes, big-endian)
        lock.lock()
        let sn = sequenceNumber
        sequenceNumber = sequenceNumber &+ 1
        lock.unlock()
        
        packet.append(UInt8((sn >> 24) & 0xFF))
        packet.append(UInt8((sn >> 16) & 0xFF))
        packet.append(UInt8((sn >> 8) & 0xFF))
        packet.append(UInt8(sn & 0xFF))
        
        // Una: sn - 1 (4 bytes, big-endian)
        let una = sn > 0 ? sn - 1 : 0
        packet.append(UInt8((una >> 24) & 0xFF))
        packet.append(UInt8((una >> 16) & 0xFF))
        packet.append(UInt8((una >> 8) & 0xFF))
        packet.append(UInt8(una & 0xFF))
        
        // Len: payload length (4 bytes, big-endian)
        let len = UInt32(data.count)
        packet.append(UInt8((len >> 24) & 0xFF))
        packet.append(UInt8((len >> 16) & 0xFF))
        packet.append(UInt8((len >> 8) & 0xFF))
        packet.append(UInt8(len & 0xFF))
        
        // Payload
        packet.append(data)
        
        return packet
    }
    
    /// 解封装 KCP 数据包
    func decapsulate(_ packet: Data) -> Data? {
        NSLog("🎭 KCP: Decapsulating \(packet.count) bytes")
        
        // 验证最小长度: 24 bytes header
        guard packet.count >= 24 else {
            NSLog("❌ KCP: Packet too short (\(packet.count) < 24)")
            return nil
        }
        
        // 验证 cmd (应该是 0x51)
        guard packet[4] == 0x51 else {
            NSLog("❌ KCP: Invalid cmd byte: 0x\(String(format: "%02x", packet[4]))")
            return nil
        }
        
        // 提取 payload (跳过 24 字节 header)
        let payload = Data(packet[24...])
        NSLog("🎭 KCP: Extracted \(payload.count) bytes payload")
        return payload
    }
    
    /// 提取 header 中的客户端 ID
    func extractHeaderID(_ packet: Data) -> Data? {
        guard packet.count >= 4 else {
            return nil
        }
        
        // Conv at bytes 0-3
        return Data(packet[0..<4])
    }
}

// MARK: - Generic Gaming Template

/// 通用游戏协议模板
/// 模拟游戏 UDP 协议格式
/// 与服务端保持一致: Header: [magic(4)] [sessionID(4)] [seq(2)] [type(1)] [flags(1)] = 12 bytes
class GenericGamingTemplate: ProtocolTemplate {
    let templateID: UInt8 = 3
    let name = "GenericGaming"
    
    private var sequenceNumber: UInt16 = 0
    private let lock = NSLock()
    
    /// 封装数据为游戏协议格式
    /// Header: [magic(4)] [sessionID(4)] [seq(2)] [type(1)] [flags(1)] [payload]
    /// Total header: 12 bytes (与服务端一致)
    func encapsulate(_ data: Data, clientID: Data) -> Data {
        var packet = Data()
        
        // Magic: "GAME" (0x47414D45)
        packet.append(contentsOf: [0x47, 0x41, 0x4D, 0x45])
        
        // Session ID: 从 clientID 派生 (取前4字节)
        var sessionID = clientID.prefix(4)
        while sessionID.count < 4 {
            sessionID.append(0x00)
        }
        packet.append(sessionID)
        
        // Sequence: 递增序列号 (2 bytes, big-endian - 与服务端一致)
        lock.lock()
        let seq = sequenceNumber
        sequenceNumber = sequenceNumber &+ 1
        lock.unlock()
        
        packet.append(UInt8((seq >> 8) & 0xFF))
        packet.append(UInt8(seq & 0xFF))
        
        // Packet type (1 byte): 0x01-0x05 (与服务端一致)
        packet.append(UInt8(1 + arc4random_uniform(5)))
        
        // Flags (1 byte): random flags (与服务端一致)
        packet.append(UInt8(arc4random_uniform(256)))
        
        // Payload
        packet.append(data)
        
        return packet
    }
    
    /// 解封装游戏协议数据包
    func decapsulate(_ packet: Data) -> Data? {
        // 验证最小长度: 12 bytes header
        guard packet.count >= 12 else {
            return nil
        }
        
        // 验证 magic (应该是 "GAME")
        guard packet[0] == 0x47 && packet[1] == 0x41 && 
              packet[2] == 0x4D && packet[3] == 0x45 else {
            return nil
        }
        
        // 提取 payload (跳过 12 字节 header)
        return Data(packet[12...])
    }
    
    /// 提取 header 中的客户端 ID
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
        return Data(packet[4..<8])
    }
}

// MARK: - Template Type Enum

enum TemplateType: UInt8 {
    case none = 0
    case quic = 1
    case kcp = 2
    case gaming = 3
}

// MARK: - Template Factory

class TemplateFactory {
    /// 创建协议模板
    static func createTemplate(_ type: TemplateType) -> ProtocolTemplate? {
        switch type {
        case .none:
            return nil
        case .quic:
            return QuicTemplate()
        case .kcp:
            return KcpTemplate()
        case .gaming:
            return GenericGamingTemplate()
        }
    }
    
    /// 从整数创建模板
    static func createTemplate(fromInt value: Int) -> ProtocolTemplate? {
        guard let type = TemplateType(rawValue: UInt8(value)) else {
            return nil
        }
        return createTemplate(type)
    }
}

// MARK: - Protocol Extensions for Handshake

extension QuicTemplate {
    var id: UInt8 { return templateID }
    
    func getParams() -> [String: Any] {
        return [:]
    }
}

extension KcpTemplate {
    var id: UInt8 { return templateID }
    
    func getParams() -> [String: Any] {
        return [:]
    }
}

extension GenericGamingTemplate {
    var id: UInt8 { return templateID }
    
    func getParams() -> [String: Any] {
        return [:]
    }
}
