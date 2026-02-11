import Foundation
import Capacitor

/**
 * MorphProtocol Capacitor Plugin
 *
 * 架构说明：MorphProtocol 的网络逻辑已移入 Network Extension 进程（PacketTunnelProvider），
 * 解决 iOS 进程隔离导致的 localhost UDP 不可达问题。
 *
 * 此插件现在的职责：
 * - connect: 验证参数，构建 morphConfig JSON，供 WireGuardPlugin 传入 Extension
 * - disconnect / getStatus: 保留接口兼容性
 * - testObfuscation: 本地测试混淆算法
 */
@objc(MorphProtocolPlugin)
public class MorphProtocolPlugin: CAPPlugin {
    private var connectionStatus: String = "disconnected"
    private var lastMorphConfig: [String: Any]?

    /// 验证参数并构建 morphConfig JSON。
    /// 实际网络连接由 WireGuardPlugin → PacketTunnelProvider 内的 MorphUDPClient 处理。
    @objc func connect(_ call: CAPPluginCall) {
        NSLog("🔵 MorphProtocolPlugin: connect() called (config-only mode)")

        guard let host = call.getString("host") else {
            call.reject("Missing host parameter")
            return
        }
        guard let port = call.getInt("port") else {
            call.reject("Missing port parameter")
            return
        }
        guard let encryptionKey = call.getString("encryptionKey") else {
            call.reject("Missing encryptionKey parameter")
            return
        }
        guard let userId = call.getString("userId") else {
            call.reject("Missing userId parameter")
            return
        }

        let morphConfig: [String: Any] = [
            "host": host,
            "port": port,
            "encryptionKey": encryptionKey,
            "userId": userId,
            "obfuscationLayer": call.getInt("obfuscationLayer") ?? 3,
            "paddingLength": call.getInt("paddingLength") ?? 8,
            "templateType": call.getInt("templateType") ?? 1,
            "heartbeatInterval": call.getInt("heartbeatInterval") ?? 120000,
            "inactivityTimeout": call.getInt("inactivityTimeout") ?? 30000,
            "maxRetries": call.getInt("maxRetries") ?? 10,
            "handshakeInterval": call.getInt("handshakeInterval") ?? 5000
        ]

        self.lastMorphConfig = morphConfig
        self.connectionStatus = "configured"

        NSLog("🔵 MorphProtocol: config ready for \(host):\(port)")

        // 将 morphConfig 序列化为 JSON 字符串，前端可以传给 WireGuard.connect()
        if let jsonData = try? JSONSerialization.data(withJSONObject: morphConfig),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            call.resolve([
                "success": true,
                "message": "MorphProtocol config ready (will run in Extension)",
                "morphConfig": jsonString
            ])
        } else {
            call.reject("Failed to serialize MorphProtocol config")
        }
    }

    @objc func disconnect(_ call: CAPPluginCall) {
        NSLog("🔵 MorphProtocolPlugin: disconnect()")
        connectionStatus = "disconnected"
        lastMorphConfig = nil

        notifyListeners("statusChanged", data: [
            "status": "disconnected"
        ])

        call.resolve([
            "success": true,
            "message": "Disconnected"
        ])
    }

    @objc func getStatus(_ call: CAPPluginCall) {
        call.resolve([
            "status": connectionStatus
        ])
    }

    @objc func send(_ call: CAPPluginCall) {
        // 不再支持直接发送数据，数据转发在 Extension 内完成
        call.reject("Direct send not supported. Data forwarding runs inside Network Extension.")
    }

    // MARK: - testObfuscation

    @objc func testObfuscation(_ call: CAPPluginCall) {
        do {
            let obfuscator = MorphObfuscator(key: Int.random(in: 0...255), layer: 3, paddingLength: 8)

            let testData = Data((0..<64).map { _ in UInt8.random(in: 0...255) })
            let obfuscated = obfuscator.obfuscate(testData)
            let deobfuscated = obfuscator.deobfuscate(obfuscated)

            let match = testData == deobfuscated
            let dynamism = obfuscator.testDynamism(testData: testData, iterations: 10)

            call.resolve([
                "success": match && dynamism,
                "message": match
                    ? (dynamism ? "OK: roundtrip + dynamism" : "WARN: roundtrip OK but low dynamism")
                    : "FAIL: data mismatch after roundtrip"
            ])
        }
    }
}
