    //
    //  MorphExtensionProxy.swift
    //  WireGuardExtension
    //
    //  轻量级 MorphProtocol UDP 代理，运行在 Network Extension 进程中。
    //  使用 BSD socket API 监听本地 UDP（NWListener 在 Extension 中无法接收 wireguard-go 的包）。
    //  WireGuard → 本地代理 → 混淆+封装 → 远程服务器 → 解封装+解混淆 → WireGuard
    //

    import Foundation

    class MorphExtensionProxy {
        private let queue = DispatchQueue(label: "com.morphvpn.morphproxy", qos: .userInitiated)
        
        // BSD socket 本地监听
        private var localSocket: Int32 = -1
        private var localPort: UInt16 = 0
        
        // 远程服务器 BSD socket
        private var serverSocket: Int32 = -1
        private let remoteHost: String
        private let remotePort: UInt16
        
        // WireGuard 客户端地址（首次收到包时记录）
        private var wgClientAddr: sockaddr_in?
        private var wgClientAddrLen: socklen_t = 0
        
        // 混淆组件
        private let obfuscator: MorphObfuscator
        private let template: ProtocolTemplate?
        private let clientID: Data
        
        // 统计
        private var wgToServerCount = 0
        private var serverToWgCount = 0
        private var running = false
        
        init(host: String,
            sessionPort: UInt16,
            key: Int,
            layer: Int,
            padding: Int,
            templateId: Int,
            clientID: Data,
            fnInitor: [String: Any]?) throws {
            
            self.remoteHost = host
            self.remotePort = sessionPort
            self.clientID = clientID
            
            // 初始化混淆器
            if let fnInitor = fnInitor,
            let subTableInts = fnInitor["substitutionTable"] as? [Int],
            let randVal = fnInitor["randomValue"] as? Int {
                let subTable = subTableInts.map { UInt8($0 & 0xFF) }
                self.obfuscator = MorphObfuscator(
                    key: key, layer: layer, paddingLength: padding,
                    substitutionTable: subTable, randomValue: UInt8(randVal & 0xFF)
                )
                SharedLog.shared.log("🎭 Proxy: using App fnInitor (subTable=\(subTable.count), randVal=\(randVal))")
            } else {
                self.obfuscator = MorphObfuscator(key: key, layer: layer, paddingLength: padding)
                SharedLog.shared.log("⚠️ Proxy: no fnInitor, using random")
            }
            
            // 创建协议模板
            if let type = TemplateType(rawValue: UInt8(templateId)) {
                self.template = TemplateFactory.createTemplate(type)
            } else {
                self.template = nil
            }
            
            SharedLog.shared.log("🎭 Proxy init: host=\(host) port=\(sessionPort) key=\(key) tpl=\(template?.name ?? "None")")
        }
        
        /// 启动本地 UDP 代理，返回监听端口
        func start() -> UInt16? {
            // 1. 创建本地 UDP socket
            localSocket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
            guard localSocket >= 0 else {
                SharedLog.shared.log("❌ Proxy: local socket() failed, errno=\(errno)")
                return nil
            }
            
            // 允许端口复用
            var reuse: Int32 = 1
            setsockopt(localSocket, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))
            
            // 绑定到 127.0.0.1:0（系统分配端口）
            var bindAddr = sockaddr_in()
            bindAddr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
            bindAddr.sin_family = sa_family_t(AF_INET)
            bindAddr.sin_port = 0  // 系统分配
            bindAddr.sin_addr.s_addr = inet_addr("127.0.0.1")
            
            let bindResult = withUnsafePointer(to: &bindAddr) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                    Darwin.bind(localSocket, sockPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
            
            guard bindResult == 0 else {
                SharedLog.shared.log("❌ Proxy: bind() failed, errno=\(errno)")
                Darwin.close(localSocket)
                localSocket = -1
                return nil
            }
            
            // 获取分配的端口
            var assignedAddr = sockaddr_in()
            var addrLen = socklen_t(MemoryLayout<sockaddr_in>.size)
            withUnsafeMutablePointer(to: &assignedAddr) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                    getsockname(localSocket, sockPtr, &addrLen)
                }
            }
            localPort = UInt16(bigEndian: assignedAddr.sin_port)
            
            SharedLog.shared.log("📡 Proxy: local BSD socket bound to 127.0.0.1:\(localPort), fd=\(localSocket)")
            
            // 2. 创建远程服务器 UDP socket
            serverSocket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
            guard serverSocket >= 0 else {
                SharedLog.shared.log("❌ Proxy: server socket() failed, errno=\(errno)")
                Darwin.close(localSocket)
                localSocket = -1
                return nil
            }
            
            // connect 到远程服务器（之后可以用 send/recv）
            var remoteAddr = sockaddr_in()
            remoteAddr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
            remoteAddr.sin_family = sa_family_t(AF_INET)
            remoteAddr.sin_port = remotePort.bigEndian
            remoteAddr.sin_addr.s_addr = inet_addr(remoteHost)
            
            let connectResult = withUnsafePointer(to: &remoteAddr) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                    Darwin.connect(serverSocket, sockPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
            
            if connectResult == 0 {
                SharedLog.shared.log("✅ Proxy: server socket connected to \(remoteHost):\(remotePort), fd=\(serverSocket)")
            } else {
                SharedLog.shared.log("⚠️ Proxy: server connect() errno=\(errno)")
            }
            
            // 3. 启动收发线程
            running = true
            
            // WireGuard → Server 线程
            queue.async { [weak self] in
                self?.receiveFromWireGuardLoop()
            }
            
            // Server → WireGuard 线程
            DispatchQueue(label: "com.morphvpn.morphproxy.server", qos: .userInitiated).async { [weak self] in
                self?.receiveFromServerLoop()
            }
            
            SharedLog.shared.log("✅ Proxy started on 127.0.0.1:\(localPort)")
            return localPort
        }
        
        func stop() {
            SharedLog.shared.log("🔌 Proxy stopping (WG→Srv:\(wgToServerCount) Srv→WG:\(serverToWgCount))")
            running = false
            if localSocket >= 0 { Darwin.close(localSocket); localSocket = -1 }
            if serverSocket >= 0 { Darwin.close(serverSocket); serverSocket = -1 }
        }
        
        // MARK: - WireGuard → Server
        
        private func receiveFromWireGuardLoop() {
            var buffer = [UInt8](repeating: 0, count: 65536)
            var srcAddr = sockaddr_in()
            var srcAddrLen = socklen_t(MemoryLayout<sockaddr_in>.size)
            
            SharedLog.shared.log("📡 Proxy: WG recv loop started, fd=\(localSocket)")
            
            while running && localSocket >= 0 {
                srcAddrLen = socklen_t(MemoryLayout<sockaddr_in>.size)
                let n = withUnsafeMutablePointer(to: &srcAddr) { ptr in
                    ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                        recvfrom(localSocket, &buffer, buffer.count, 0, sockPtr, &srcAddrLen)
                    }
                }
                
                guard n > 0 else {
                    if !running { break }
                    if errno == EAGAIN || errno == EINTR { continue }
                    SharedLog.shared.log("❌ Proxy: WG recvfrom error, errno=\(errno), n=\(n)")
                    break
                }
                
                // 记录 WireGuard 客户端地址（用于回包）
                if wgClientAddr == nil {
                    wgClientAddr = srcAddr
                    wgClientAddrLen = srcAddrLen
                    SharedLog.shared.log("📡 Proxy: WG client addr recorded, port=\(UInt16(bigEndian: srcAddr.sin_port))")
                }
                
                let data = Data(bytes: buffer, count: n)
                forwardToServer(data)
            }
            
            SharedLog.shared.log("📡 Proxy: WG recv loop ended")
        }
        
        private func forwardToServer(_ data: Data) {
            wgToServerCount += 1
            if wgToServerCount <= 5 || wgToServerCount % 100 == 0 {
                SharedLog.shared.log("📤 WG→Srv #\(wgToServerCount) len=\(data.count)")
            }
            
            // 混淆 + 协议封装
            let obfuscated = obfuscator.obfuscate(data)
            let packet: Data
            if let template = self.template {
                packet = template.encapsulate(obfuscated, clientID: clientID)
            } else {
                packet = obfuscated
            }
            
            // 发送到远程服务器
            let sent = packet.withUnsafeBytes { ptr in
                Darwin.send(serverSocket, ptr.baseAddress!, packet.count, 0)
            }
            
            if sent < 0 && wgToServerCount <= 5 {
                SharedLog.shared.log("❌ WG→Srv send error, errno=\(errno)")
            }
        }
        
        // MARK: - Server → WireGuard
        
        private func receiveFromServerLoop() {
            var buffer = [UInt8](repeating: 0, count: 65536)
            
            SharedLog.shared.log("📡 Proxy: Server recv loop started, fd=\(serverSocket)")
            
            while running && serverSocket >= 0 {
                let n = Darwin.recv(serverSocket, &buffer, buffer.count, 0)
                
                guard n > 0 else {
                    if !running { break }
                    if errno == EAGAIN || errno == EINTR { continue }
                    SharedLog.shared.log("❌ Proxy: Server recv error, errno=\(errno), n=\(n)")
                    break
                }
                
                let data = Data(bytes: buffer, count: n)
                forwardToWireGuard(data)
            }
            
            SharedLog.shared.log("📡 Proxy: Server recv loop ended")
        }
        
        private func forwardToWireGuard(_ data: Data) {
            serverToWgCount += 1
            if serverToWgCount <= 5 || serverToWgCount % 100 == 0 {
                SharedLog.shared.log("📥 Srv→WG #\(serverToWgCount) len=\(data.count)")
            }
            
            // 协议解封装 + 解混淆
            let obfuscated: Data
            if let template = self.template {
                guard let extracted = template.decapsulate(data) else {
                    SharedLog.shared.log("❌ Srv→WG decapsulate failed, len=\(data.count)")
                    return
                }
                obfuscated = extracted
            } else {
                obfuscated = data
            }
            
            let deobfuscated = obfuscator.deobfuscate(obfuscated)
            
            // 发回给 WireGuard
            guard var clientAddr = wgClientAddr else {
                if serverToWgCount <= 3 {
                    SharedLog.shared.log("⚠️ Srv→WG: no WG client addr yet, dropping")
                }
                return
            }
            
            let sent = deobfuscated.withUnsafeBytes { ptr in
                withUnsafeMutablePointer(to: &clientAddr) { addrPtr in
                    addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                        sendto(localSocket, ptr.baseAddress!, deobfuscated.count, 0, sockPtr, wgClientAddrLen)
                    }
                }
            }
            
            if sent < 0 && serverToWgCount <= 5 {
                SharedLog.shared.log("❌ Srv→WG sendto error, errno=\(errno)")
            }
        }
    }
