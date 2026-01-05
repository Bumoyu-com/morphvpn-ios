import Foundation
import Darwin

/// ICMP Echo Request/Reply 实现
class ICMPPinger {
    private let host: String
    private let timeout: TimeInterval
    private var socket: Int32 = -1
    
    init(host: String, timeout: TimeInterval) {
        self.host = host
        self.timeout = timeout
    }
    
    deinit {
        closeSocket()
    }
    
    /// 执行单次 ping，返回延迟（毫秒）或 nil
    func ping() -> Double? {
        guard let address = resolveHost() else {
            return nil
        }
        
        guard createSocket() else {
            return nil
        }
        
        defer { closeSocket() }
        
        let identifier = UInt16(ProcessInfo.processInfo.processIdentifier & 0xFFFF)
        let sequenceNumber = UInt16.random(in: 0...UInt16.max)
        
        guard let packet = createICMPPacket(identifier: identifier, sequenceNumber: sequenceNumber) else {
            return nil
        }
        
        let startTime = Date()
        
        // 发送 ICMP Echo Request
        guard sendPacket(packet, to: address) else {
            return nil
        }
        
        // 接收 ICMP Echo Reply
        guard receiveReply(identifier: identifier, sequenceNumber: sequenceNumber) else {
            return nil
        }
        
        let latency = Date().timeIntervalSince(startTime) * 1000.0 // 转换为毫秒
        return latency
    }
    
    // MARK: - Private Methods
    
    private func resolveHost() -> sockaddr_in? {
        var hints = addrinfo()
        hints.ai_family = AF_INET
        hints.ai_socktype = SOCK_DGRAM
        
        var result: UnsafeMutablePointer<addrinfo>?
        let status = getaddrinfo(host, nil, &hints, &result)
        
        guard status == 0, let info = result else {
            return nil
        }
        
        defer { freeaddrinfo(info) }
        
        guard let addr = info.pointee.ai_addr else {
            return nil
        }
        
        return addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
    }
    
    private func createSocket() -> Bool {
        socket = Darwin.socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP)
        guard socket >= 0 else {
            return false
        }
        
        // 设置超时
        var tv = timeval()
        tv.tv_sec = Int(timeout)
        tv.tv_usec = Int32((timeout.truncatingRemainder(dividingBy: 1.0)) * 1_000_000)
        
        setsockopt(socket, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))
        
        return true
    }
    
    private func closeSocket() {
        if socket >= 0 {
            close(socket)
            socket = -1
        }
    }
    
    private func createICMPPacket(identifier: UInt16, sequenceNumber: UInt16) -> Data? {
        var packet = Data(count: 64)
        
        packet.withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) in
            guard let baseAddress = ptr.baseAddress else { return }
            
            // ICMP Header
            var header = ICMPHeader()
            header.type = 8  // Echo Request
            header.code = 0
            header.checksum = 0
            header.identifier = identifier.bigEndian
            header.sequenceNumber = sequenceNumber.bigEndian
            
            // 复制 header
            baseAddress.copyMemory(from: &header, byteCount: MemoryLayout<ICMPHeader>.size)
            
            // 填充数据
            let dataStart = baseAddress.advanced(by: MemoryLayout<ICMPHeader>.size)
            let dataSize = 64 - MemoryLayout<ICMPHeader>.size
            memset(dataStart, 0x42, dataSize)
            
            // 计算校验和
            let checksum = calculateChecksum(data: packet)
            var checksumBigEndian = checksum.bigEndian
            baseAddress.advanced(by: 2).copyMemory(from: &checksumBigEndian, byteCount: 2)
        }
        
        return packet
    }
    
    private func calculateChecksum(data: Data) -> UInt16 {
        var sum: UInt32 = 0
        
        data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            let uint16Ptr = ptr.bindMemory(to: UInt16.self)
            for i in 0..<uint16Ptr.count {
                sum += UInt32(uint16Ptr[i])
            }
        }
        
        // 处理奇数字节
        if data.count % 2 != 0 {
            sum += UInt32(data[data.count - 1]) << 8
        }
        
        // 折叠进位
        while (sum >> 16) != 0 {
            sum = (sum & 0xFFFF) + (sum >> 16)
        }
        
        return ~UInt16(sum)
    }
    
    private func sendPacket(_ packet: Data, to address: sockaddr_in) -> Bool {
        var addr = address
        let sent = packet.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> Int in
            withUnsafePointer(to: &addr) { addrPtr in
                addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                    sendto(socket, ptr.baseAddress, packet.count, 0, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
        }
        
        return sent == packet.count
    }
    
    private func receiveReply(identifier: UInt16, sequenceNumber: UInt16) -> Bool {
        var buffer = Data(count: 1024)
        
        let received = buffer.withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) -> Int in
            recv(socket, ptr.baseAddress, buffer.count, 0)
        }
        
        guard received > 0 else {
            return false
        }
        
        // 跳过 IP header (通常 20 字节)
        let ipHeaderLength = 20
        guard received > ipHeaderLength + MemoryLayout<ICMPHeader>.size else {
            return false
        }
        
        // 解析 ICMP header
        let icmpData = buffer.subdata(in: ipHeaderLength..<received)
        return icmpData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> Bool in
            guard let baseAddress = ptr.baseAddress else { return false }
            let header = baseAddress.load(as: ICMPHeader.self)
            
            // 验证是否是我们的回复
            return header.type == 0 &&  // Echo Reply
                   UInt16(bigEndian: header.identifier) == identifier &&
                   UInt16(bigEndian: header.sequenceNumber) == sequenceNumber
        }
    }
}

// MARK: - ICMP Header Structure

private struct ICMPHeader {
    var type: UInt8 = 0
    var code: UInt8 = 0
    var checksum: UInt16 = 0
    var identifier: UInt16 = 0
    var sequenceNumber: UInt16 = 0
}
