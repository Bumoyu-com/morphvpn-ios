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
        NSLog("🏓 ICMPPinger: Initialized for host: \(host), timeout: \(timeout)s")
    }
    
    deinit {
        closeSocket()
    }
    
    /// 执行单次 ping，返回延迟（毫秒）或 nil
    func ping() -> Double? {
        NSLog("🏓 ICMPPinger: Starting ping to \(host)")
        
        guard let address = resolveHost() else {
            NSLog("❌ ICMPPinger: Failed to resolve host: \(host)")
            return nil
        }
        
        let ipString = String(cString: inet_ntoa(address.sin_addr))
        NSLog("🏓 ICMPPinger: Resolved \(host) to \(ipString)")
        
        guard createSocket() else {
            NSLog("❌ ICMPPinger: Failed to create socket")
            return nil
        }
        
        defer { closeSocket() }
        
        let identifier = UInt16(ProcessInfo.processInfo.processIdentifier & 0xFFFF)
        let sequenceNumber = UInt16.random(in: 0...UInt16.max)
        
        NSLog("🏓 ICMPPinger: Using identifier: \(identifier), sequence: \(sequenceNumber)")
        
        guard let packet = createICMPPacket(identifier: identifier, sequenceNumber: sequenceNumber) else {
            NSLog("❌ ICMPPinger: Failed to create ICMP packet")
            return nil
        }
        
        NSLog("🏓 ICMPPinger: Created ICMP packet, size: \(packet.count) bytes")
        
        let startTime = Date()
        
        // 发送 ICMP Echo Request
        guard sendPacket(packet, to: address) else {
            NSLog("❌ ICMPPinger: Failed to send packet")
            return nil
        }
        
        NSLog("🏓 ICMPPinger: Packet sent successfully")
        
        // 接收 ICMP Echo Reply
        guard receiveReply(identifier: identifier, sequenceNumber: sequenceNumber) else {
            NSLog("❌ ICMPPinger: Failed to receive reply (timeout or error)")
            return nil
        }
        
        let latency = Date().timeIntervalSince(startTime) * 1000.0 // 转换为毫秒
        NSLog("✅ ICMPPinger: Received reply, latency: \(String(format: "%.2f", latency)) ms")
        return latency
    }
    
    // MARK: - Private Methods
    
    private func resolveHost() -> sockaddr_in? {
        NSLog("🏓 ICMPPinger: Resolving host: \(host)")
        
        // 不设置 hints，让系统自动选择
        var result: UnsafeMutablePointer<addrinfo>?
        let status = getaddrinfo(host, nil, nil, &result)
        
        if status != 0 {
            let errorStr = String(cString: gai_strerror(status))
            NSLog("❌ ICMPPinger: getaddrinfo failed: \(errorStr) (status: \(status))")
            return nil
        }
        
        guard let info = result else {
            NSLog("❌ ICMPPinger: getaddrinfo returned null")
            return nil
        }
        
        defer { freeaddrinfo(info) }
        
        // 遍历结果，找到 IPv4 地址
        var current = info
        while true {
            if current.pointee.ai_family == AF_INET {
                guard let addr = current.pointee.ai_addr else {
                    NSLog("❌ ICMPPinger: ai_addr is null")
                    return nil
                }
                
                let sockaddr = addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
                let ipString = String(cString: inet_ntoa(sockaddr.sin_addr))
                NSLog("🏓 ICMPPinger: Successfully resolved to IPv4: \(ipString)")
                return sockaddr
            }
            
            guard let next = current.pointee.ai_next else {
                break
            }
            current = next
        }
        
        NSLog("❌ ICMPPinger: No IPv4 address found")
        return nil
    }
    
    private func createSocket() -> Bool {
        NSLog("🏓 ICMPPinger: Creating socket")
        
        // iOS 需要使用 SOCK_DGRAM 而不是 SOCK_RAW
        socket = Darwin.socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP)
        
        if socket < 0 {
            let error = String(cString: strerror(errno))
            NSLog("❌ ICMPPinger: socket() failed: \(error) (errno: \(errno))")
            return false
        }
        
        NSLog("🏓 ICMPPinger: Socket created successfully (fd: \(socket))")
        
        // 设置接收超时
        var tv = timeval()
        tv.tv_sec = Int(timeout)
        tv.tv_usec = Int32((timeout.truncatingRemainder(dividingBy: 1.0)) * 1_000_000)
        
        let rcvResult = setsockopt(socket, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))
        if rcvResult != 0 {
            let error = String(cString: strerror(errno))
            NSLog("⚠️ ICMPPinger: setsockopt(SO_RCVTIMEO) failed: \(error)")
        } else {
            NSLog("🏓 ICMPPinger: Set receive timeout to \(timeout)s")
        }
        
        // 设置发送超时
        let sndResult = setsockopt(socket, SOL_SOCKET, SO_SNDTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))
        if sndResult != 0 {
            let error = String(cString: strerror(errno))
            NSLog("⚠️ ICMPPinger: setsockopt(SO_SNDTIMEO) failed: \(error)")
        }
        
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
        
        // 第一步：写入 header 和填充数据
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
        }
        
        // 第二步：计算并写入校验和（避免重叠访问）
        let checksum = calculateChecksum(data: packet)
        packet.withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) in
            guard let baseAddress = ptr.baseAddress else { return }
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
        NSLog("🏓 ICMPPinger: Sending packet (\(packet.count) bytes)")
        
        var addr = address
        let sent = packet.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> Int in
            withUnsafePointer(to: &addr) { addrPtr in
                addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                    sendto(socket, ptr.baseAddress, packet.count, 0, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
        }
        
        if sent < 0 {
            let error = String(cString: strerror(errno))
            NSLog("❌ ICMPPinger: sendto() failed: \(error) (errno: \(errno))")
            return false
        }
        
        if sent != packet.count {
            NSLog("⚠️ ICMPPinger: Partial send: \(sent)/\(packet.count) bytes")
            return false
        }
        
        NSLog("🏓 ICMPPinger: Sent \(sent) bytes successfully")
        return true
    }
    
    private func receiveReply(identifier: UInt16, sequenceNumber: UInt16) -> Bool {
        NSLog("🏓 ICMPPinger: Waiting for reply (timeout: \(timeout)s)")
        
        var buffer = Data(count: 1024)
        let bufferSize = buffer.count
        
        let received = buffer.withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) -> Int in
            recv(socket, ptr.baseAddress, bufferSize, 0)
        }
        
        if received < 0 {
            let error = String(cString: strerror(errno))
            if errno == EAGAIN || errno == EWOULDBLOCK {
                NSLog("⏱️ ICMPPinger: recv() timeout")
            } else {
                NSLog("❌ ICMPPinger: recv() failed: \(error) (errno: \(errno))")
            }
            return false
        }
        
        if received == 0 {
            NSLog("❌ ICMPPinger: recv() returned 0 (connection closed)")
            return false
        }
        
        NSLog("🏓 ICMPPinger: Received \(received) bytes")
        
        // SOCK_DGRAM 不包含 IP header，直接是 ICMP 数据
        guard received >= MemoryLayout<ICMPHeader>.size else {
            NSLog("❌ ICMPPinger: Packet too small: \(received) bytes")
            return false
        }
        
        // 解析 ICMP header
        let icmpData = buffer.prefix(received)
        let isValid = icmpData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> Bool in
            guard let baseAddress = ptr.baseAddress else {
                NSLog("❌ ICMPPinger: Failed to get base address")
                return false
            }
            
            let header = baseAddress.load(as: ICMPHeader.self)
            
            NSLog("🏓 ICMPPinger: ICMP type: \(header.type), code: \(header.code)")
            NSLog("🏓 ICMPPinger: Identifier: \(UInt16(bigEndian: header.identifier)) (expected: \(identifier))")
            NSLog("🏓 ICMPPinger: Sequence: \(UInt16(bigEndian: header.sequenceNumber)) (expected: \(sequenceNumber))")
            
            // 验证是否是我们的回复
            let isEchoReply = header.type == 0  // Echo Reply
            let idMatch = UInt16(bigEndian: header.identifier) == identifier
            let seqMatch = UInt16(bigEndian: header.sequenceNumber) == sequenceNumber
            
            if !isEchoReply {
                NSLog("❌ ICMPPinger: Not an Echo Reply (type: \(header.type))")
            }
            if !idMatch {
                NSLog("❌ ICMPPinger: Identifier mismatch")
            }
            if !seqMatch {
                NSLog("❌ ICMPPinger: Sequence number mismatch")
            }
            
            return isEchoReply && idMatch && seqMatch
        }
        
        if isValid {
            NSLog("✅ ICMPPinger: Valid reply received")
        } else {
            NSLog("❌ ICMPPinger: Invalid reply")
        }
        
        return isValid
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
