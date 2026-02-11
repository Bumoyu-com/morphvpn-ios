import NetworkExtension
import WireGuardKit
import Network
import os.log

class PacketTunnelProvider: NEPacketTunnelProvider {

    private var adapter: WireGuardAdapter?
    private var morphClient: MorphUDPClient?
    private lazy var logger = Logger(subsystem: "com.morphvpn.app.WireGuardExtension", category: "PacketTunnel")

    // MARK: - Lifecycle

    override init() {
        // 在 Go runtime 初始化前设置内存限制，防止 Extension 超过 50MB 被系统杀死
        setenv("GOGC", "10", 1)
        setenv("GOMEMLIMIT", "30MiB", 1)
        super.init()
        NSLog("🎯 PacketTunnelProvider: init()")
    }

    override func startTunnel(options: [String: NSObject]?,
                              completionHandler: @escaping (Error?) -> Void) {
        NSLog("🚀 PacketTunnelProvider: startTunnel()")
        SharedLog.clear()
        SharedLog.shared.log("startTunnel()")

        guard let protocolConfiguration = self.protocolConfiguration as? NETunnelProviderProtocol,
              let providerConfig = protocolConfiguration.providerConfiguration else {
            NSLog("❌ PacketTunnel: Invalid protocol configuration")
            completionHandler(makeError(code: 1, message: "Invalid protocol configuration"))
            return
        }

        // 打印 providerConfiguration 的所有 key，帮助调试
        NSLog("📋 PacketTunnel: providerConfig keys = \(Array(providerConfig.keys))")

        guard let wgConfigString = providerConfig["wg_config"] as? String else {
            NSLog("❌ PacketTunnel: wg_config not found in providerConfig")
            completionHandler(makeError(code: 2, message: "WireGuard config not found"))
            return
        }

        NSLog("📋 PacketTunnel: wg_config length = \(wgConfigString.count) bytes")

        // 检查是否有 MorphProtocol 配置
        if let morphConfigJSON = providerConfig["morph_config"] as? String {
            NSLog("🎭 PacketTunnel: morph_config found (\(morphConfigJSON.count) bytes), starting with obfuscation")
            startWithMorphProtocol(wgConfig: wgConfigString,
                                   morphConfigJSON: morphConfigJSON,
                                   completionHandler: completionHandler)
        } else {
            NSLog("📡 PacketTunnel: No morph_config, starting plain WireGuard")
            startPlainWireGuard(wgConfig: wgConfigString,
                                completionHandler: completionHandler)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason,
                             completionHandler: @escaping () -> Void) {
        NSLog("🛑 PacketTunnelProvider: stopTunnel(), reason: \(reason.rawValue)")

        morphClient?.disconnect()
        morphClient = nil

        adapter?.stop { error in
            if let error = error {
                NSLog("❌ Error stopping WireGuard adapter: \(error)")
            } else {
                NSLog("✅ WireGuard tunnel stopped")
            }
            completionHandler()
        }
        adapter = nil
    }

    override func handleAppMessage(_ messageData: Data,
                                   completionHandler: ((Data?) -> Void)?) {
        guard let message = String(data: messageData, encoding: .utf8) else {
            completionHandler?(nil)
            return
        }

        NSLog("📨 handleAppMessage: \(message)")

        switch message {
        case "getStatus":
            let status = getMorphStatus()
            let responseData = try? JSONSerialization.data(withJSONObject: status)
            completionHandler?(responseData)
        default:
            completionHandler?(nil)
        }
    }

    // MARK: - MorphProtocol + WireGuard

    private func startWithMorphProtocol(wgConfig: String,
                                         morphConfigJSON: String,
                                         completionHandler: @escaping (Error?) -> Void) {
        guard let morphConfig = parseMorphConfig(morphConfigJSON) else {
            completionHandler(makeError(code: 10, message: "Invalid MorphProtocol config"))
            return
        }

        NSLog("🎭 MorphProtocol: host=\(morphConfig.host):\(morphConfig.port) layer=\(morphConfig.obfuscationLayer) tpl=\(morphConfig.templateType)")
        SharedLog.shared.log("MorphProtocol: host=\(morphConfig.host):\(morphConfig.port)")

        do {
            let templateType: TemplateType? = morphConfig.templateType > 0
                ? TemplateType(rawValue: UInt8(morphConfig.templateType))
                : nil

            var clientConfig = MorphClientConfig()
            clientConfig.heartbeatInterval = morphConfig.heartbeatInterval
            clientConfig.inactivityTimeout = morphConfig.inactivityTimeout
            clientConfig.maxRetries = morphConfig.maxRetries
            clientConfig.handshakeInterval = morphConfig.handshakeInterval

            let client = try MorphUDPClient(
                encryptionKey: morphConfig.encryptionKey,
                obfuscationLayer: morphConfig.obfuscationLayer,
                paddingLength: morphConfig.paddingLength,
                templateType: templateType,
                userId: morphConfig.userId,
                config: clientConfig
            )
            self.morphClient = client

            // 启动本地 UDP 代理（Extension 进程内的 localhost）
            guard let localPort = client.startLocalProxy(preferredPort: 0) else {
                completionHandler(makeError(code: 11, message: "Failed to start local UDP proxy"))
                return
            }
            NSLog("✅ MorphProtocol: local proxy on 127.0.0.1:\(localPort)")
            SharedLog.shared.log("local proxy on 127.0.0.1:\(localPort)")

            // 异步等待握手完成，不阻塞 NEPacketTunnelProvider 的内部队列
            let completionLock = NSLock()
            var completionCalled = false

            let callCompletionOnce: (Error?) -> Void = { error in
                completionLock.lock()
                let alreadyCalled = completionCalled
                completionCalled = true
                completionLock.unlock()
                
                if !alreadyCalled {
                    completionHandler(error)
                }
            }

            client.onHandshakeComplete = { [weak self] port in
                guard let self = self else { return }

                NSLog("✅ MorphProtocol: handshake done, session port=\(port)")
                NSLog("✅ MorphProtocol: connected, session=\(port), local=\(localPort)")
                SharedLog.shared.log("connected session=\(port) local=\(localPort)")

                let modifiedConfig = self.rewriteWireGuardConfig(wgConfig,
                                                                  localPort: localPort,
                                                                  excludeServerIP: morphConfig.host)
                NSLog("✅ WireGuard config rewritten, Endpoint=127.0.0.1:\(localPort), excluded server=\(morphConfig.host)")

                for line in modifiedConfig.split(separator: "\n") {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        NSLog("📋 WG config: \(trimmed)")
                        SharedLog.shared.log("WG: \(trimmed)")
                    }
                }

                self.startWireGuard(config: modifiedConfig, completionHandler: callCompletionOnce)
            }

            client.onError = { error in
                NSLog("❌ MorphProtocol: error during handshake: \(error)")
                SharedLog.shared.log("ERROR: handshake failed: \(error)")
                callCompletionOnce(NSError(domain: "com.morphvpn.WireGuardExtension",
                                           code: 13,
                                           userInfo: [NSLocalizedDescriptionKey: "MorphProtocol handshake failed: \(error)"]))
            }

            client.connectToRemote(host: morphConfig.host, port: UInt16(morphConfig.port))

            // 设置握手超时（30 秒）
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                NSLog("⚠️ MorphProtocol: handshake timeout check")
                callCompletionOnce(NSError(domain: "com.morphvpn.WireGuardExtension",
                                           code: 12,
                                           userInfo: [NSLocalizedDescriptionKey: "MorphProtocol handshake timeout"]))
            }

        } catch {
            NSLog("❌ MorphProtocol init failed: \(error)")
            completionHandler(makeError(code: 14, message: "MorphProtocol init failed: \(error)"))
        }
    }

    private func startPlainWireGuard(wgConfig: String,
                                      completionHandler: @escaping (Error?) -> Void) {
        startWireGuard(config: wgConfig, completionHandler: completionHandler)
    }

    private func startWireGuard(config: String,
                                 completionHandler: @escaping (Error?) -> Void) {
        guard let tunnelConfiguration = try? TunnelConfiguration(fromWgQuickConfig: config) else {
            completionHandler(makeError(code: 4, message: "Invalid WireGuard configuration"))
            return
        }

        adapter = WireGuardAdapter(with: self) { logLevel, message in
            // 只记录 error 级别日志，verbose 日志会消耗大量内存导致 Extension 被系统杀死
            if logLevel == .error {
                NSLog("WireGuard: [error] \(message)")
            }
        }

        adapter?.start(tunnelConfiguration: tunnelConfiguration) { [weak self] error in
            if let error = error {
                NSLog("❌ WireGuard adapter failed: \(error)")
                completionHandler(error)
            } else {
                NSLog("✅ WireGuard tunnel started")
                SharedLog.shared.log("WireGuard tunnel started")
                completionHandler(nil)
            }
        }
    }

    // MARK: - WireGuard 配置改写

    private func rewriteWireGuardConfig(_ config: String,
                                         localPort: UInt16,
                                         excludeServerIP: String? = nil) -> String {
        let lines = config.split(separator: "\n", omittingEmptySubsequences: false)
        var result: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let lower = trimmed.lowercased()

            if lower.hasPrefix("endpoint") && lower.contains("=") {
                result.append("Endpoint = 127.0.0.1:\(localPort)")
            } else if lower.hasPrefix("allowedips") && lower.contains("=") {
                let newAllowedIPs = rewriteAllowedIPs(trimmed, excludeServerIP: excludeServerIP)
                result.append(newAllowedIPs)
            } else {
                result.append(String(line))
            }
        }

        return result.joined(separator: "\n")
    }

    /// 改写 AllowedIPs：排除 127.0.0.0/8（loopback）和远程服务器 IP/32（防止路由回环）。
    private func rewriteAllowedIPs(_ line: String, excludeServerIP: String? = nil) -> String {
        guard let equalsIndex = line.firstIndex(of: "=") else { return line }
        let value = line[line.index(after: equalsIndex)...].trimmingCharacters(in: .whitespaces)
        let cidrs = value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        // 构建需要排除的 IP 列表
        var excludeIPs: [UInt32] = []
        // 始终排除 127.0.0.0/8
        // （通过 cidrCoversIP 检查处理）

        // 解析远程服务器 IP
        var serverIPValue: UInt32?
        if let serverIP = excludeServerIP {
            serverIPValue = parseIPv4(serverIP)
            if let ip = serverIPValue {
                NSLog("🔧 Will exclude server IP \(serverIP) from AllowedIPs")
            }
        }

        var newCIDRs: [String] = []

        for cidr in cidrs {
            if cidr.contains(":") {
                // IPv6 保持不变
                newCIDRs.append(cidr)
            } else {
                let split = splitCIDRExcludingIPs(cidr, serverIP: serverIPValue)
                newCIDRs.append(contentsOf: split)
            }
        }

        let result = "AllowedIPs = \(newCIDRs.joined(separator: ", "))"
        NSLog("🔧 AllowedIPs rewritten (\(newCIDRs.count) entries)")
        SharedLog.shared.log("AllowedIPs: \(newCIDRs.count) entries")
        return result
    }

    /// 将一个 IPv4 CIDR 拆分，排除 127.0.0.0/8 和指定的服务器 IP/32。
    private func splitCIDRExcludingIPs(_ cidr: String, serverIP: UInt32?) -> [String] {
        let parts = cidr.split(separator: "/")
        guard parts.count == 2, let prefix = Int(parts[1]) else { return [cidr] }

        let octets = parts[0].split(separator: ".").compactMap { UInt32($0) }
        guard octets.count == 4 else { return [cidr] }

        let ip = (octets[0] << 24) | (octets[1] << 16) | (octets[2] << 8) | octets[3]
        let mask: UInt32 = prefix == 0 ? 0 : UInt32(0xFFFFFFFF) << UInt32(32 - prefix)
        let networkAddr = ip & mask

        return splitRecursive(network: networkAddr, prefix: prefix, serverIP: serverIP)
    }

    private func splitRecursive(network: UInt32, prefix: Int, serverIP: UInt32?) -> [String] {
        let mask: UInt32 = prefix == 0 ? 0 : UInt32(0xFFFFFFFF) << UInt32(32 - prefix)
        let networkStart = network & mask
        let networkEnd = networkStart | ~mask

        let loopbackStart: UInt32 = 127 << 24
        let loopbackEnd: UInt32 = (127 << 24) | 0x00FFFFFF

        let coversLoopback = networkStart <= loopbackStart && networkEnd >= loopbackEnd
        let coversServer: Bool
        if let serverIP = serverIP {
            coversServer = serverIP >= networkStart && serverIP <= networkEnd
        } else {
            coversServer = false
        }

        // 不包含任何需要排除的 IP，直接保留
        if !coversLoopback && !coversServer {
            return [formatCIDR(network: networkStart, prefix: prefix)]
        }

        // 恰好是 127.0.0.0/8 或其子网，且不包含 server IP → 排除
        if networkStart >= loopbackStart && networkEnd <= loopbackEnd && !coversServer {
            return []
        }

        // 是 /32 且恰好是 server IP → 排除
        if prefix == 32 && serverIP != nil && networkStart == serverIP! {
            return []
        }

        // 是 /32 且是 loopback → 排除
        if prefix == 32 && networkStart >= loopbackStart && networkStart <= loopbackEnd {
            return []
        }

        // 需要继续拆分
        guard prefix < 32 else { return [] }

        let newPrefix = prefix + 1
        let halfSize: UInt32 = 1 << UInt32(31 - prefix)
        let firstHalf = networkStart
        let secondHalf = networkStart + halfSize

        var result: [String] = []
        result.append(contentsOf: splitRecursive(network: firstHalf, prefix: newPrefix, serverIP: serverIP))
        result.append(contentsOf: splitRecursive(network: secondHalf, prefix: newPrefix, serverIP: serverIP))
        return result
    }

    private func parseIPv4(_ ip: String) -> UInt32? {
        let octets = ip.split(separator: ".").compactMap { UInt32($0) }
        guard octets.count == 4 else { return nil }
        return (octets[0] << 24) | (octets[1] << 16) | (octets[2] << 8) | octets[3]
    }

    private func formatCIDR(network: UInt32, prefix: Int) -> String {
        let a = (network >> 24) & 0xFF
        let b = (network >> 16) & 0xFF
        let c = (network >> 8) & 0xFF
        let d = network & 0xFF
        return "\(a).\(b).\(c).\(d)/\(prefix)"
    }

    // MARK: - MorphProtocol 配置解析

    private struct MorphConfig {
        let host: String
        let port: Int
        let encryptionKey: String
        let userId: String
        let obfuscationLayer: Int
        let paddingLength: Int
        let templateType: Int
        let heartbeatInterval: TimeInterval
        let inactivityTimeout: TimeInterval
        let maxRetries: Int
        let handshakeInterval: TimeInterval
    }

    private func parseMorphConfig(_ jsonString: String) -> MorphConfig? {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        guard let host = json["host"] as? String,
              let port = json["port"] as? Int,
              let encryptionKey = json["encryptionKey"] as? String,
              let userId = json["userId"] as? String else {
            return nil
        }

        return MorphConfig(
            host: host,
            port: port,
            encryptionKey: encryptionKey,
            userId: userId,
            obfuscationLayer: json["obfuscationLayer"] as? Int ?? 3,
            paddingLength: json["paddingLength"] as? Int ?? 8,
            templateType: json["templateType"] as? Int ?? 1,
            heartbeatInterval: TimeInterval(json["heartbeatInterval"] as? Int ?? 120000) / 1000.0,
            inactivityTimeout: TimeInterval(json["inactivityTimeout"] as? Int ?? 30000) / 1000.0,
            maxRetries: json["maxRetries"] as? Int ?? 10,
            handshakeInterval: TimeInterval(json["handshakeInterval"] as? Int ?? 5000) / 1000.0
        )
    }

    // MARK: - Status

    private func getMorphStatus() -> [String: Any] {
        var status: [String: Any] = [:]

        if let client = morphClient {
            status["morphConnected"] = client.getSessionPort() != nil
            status["localPort"] = Int(client.getLocalPort())
            if let sp = client.getSessionPort() {
                status["sessionPort"] = Int(sp)
            }
        } else {
            status["morphConnected"] = false
        }

        return status
    }

    // MARK: - Helpers

    private func makeError(code: Int, message: String) -> NSError {
        return NSError(domain: "com.morphvpn.WireGuardExtension",
                       code: code,
                       userInfo: [NSLocalizedDescriptionKey: message])
    }
}
