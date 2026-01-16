import Foundation
import Capacitor
import Network

/**
 * MorphProtocol Capacitor Plugin
 * 提供 MorphProtocol UDP 代理功能
 * 
 * 工作流程:
 * 1. 启动本地 UDP 监听器 (NWListener)
 * 2. 连接到远程 MorphProtocol 服务器并完成握手
 * 3. WireGuard 连接到本地监听端口
 * 4. 转发 WireGuard 数据到远程服务器（经过混淆）
 * 5. 转发服务器响应到 WireGuard（经过解混淆）
 */
@objc(MorphProtocolPlugin)
public class MorphProtocolPlugin: CAPPlugin {
    private var morphClient: MorphUDPClient?
    private var localPort: UInt16 = 0
    private var sessionPort: UInt16 = 0
    private var connectionStatus: String = "disconnected"
    
    @objc func connect(_ call: CAPPluginCall) {
        NSLog("🔵 MorphProtocolPlugin: connect() called")
        
        // 必需参数
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
        
        // 可选参数
        let obfuscationLayer = call.getInt("obfuscationLayer") ?? 3
        let paddingLength = call.getInt("paddingLength") ?? 8
        let templateType = call.getInt("templateType") ?? 1
        let localProxyPort = call.getInt("localProxyPort") ?? 0
        
        NSLog("🔵 MorphProtocolPlugin: Config:")
        NSLog("   Host: \(host):\(port)")
        NSLog("   UserId: \(userId)")
        NSLog("   Layer: \(obfuscationLayer), Padding: \(paddingLength), Template: \(templateType)")
        NSLog("   LocalProxyPort: \(localProxyPort)")
        
        connectionStatus = "connecting"
        
        do {
            // 创建 MorphUDPClient
            let template = TemplateType(rawValue: UInt8(templateType))
            morphClient = try MorphUDPClient(
                encryptionKey: encryptionKey,
                obfuscationLayer: obfuscationLayer,
                paddingLength: paddingLength,
                templateType: template,
                userId: userId
            )
            
            // 设置回调
            morphClient?.onReceive = { [weak self] data in
                self?.notifyDataReceived(data)
            }
            
            morphClient?.onStateChange = { [weak self] state in
                self?.handleStateChange(state)
            }
            
            morphClient?.onError = { [weak self] error in
                NSLog("❌ MorphProtocolPlugin: Error: \(error)")
                self?.connectionStatus = "failed"
                self?.notifyListeners("statusChanged", data: [
                    "status": "failed",
                    "error": error.localizedDescription
                ])
            }
            
            morphClient?.onLocalPortReady = { [weak self] port in
                NSLog("✅ MorphProtocolPlugin: Local port ready: \(port)")
                self?.localPort = port
                self?.notifyListeners("localPortReady", data: [
                    "port": Int(port)
                ])
            }
            
            morphClient?.onHandshakeComplete = { [weak self] sessionPort in
                NSLog("✅ MorphProtocolPlugin: Handshake complete, session port: \(sessionPort)")
                self?.sessionPort = sessionPort
                self?.connectionStatus = "connected"
                self?.notifyListeners("handshakeComplete", data: [
                    "sessionPort": Int(sessionPort)
                ])
                self?.notifyListeners("statusChanged", data: [
                    "status": "connected",
                    "localPort": Int(self?.localPort ?? 0),
                    "sessionPort": Int(sessionPort)
                ])
            }
            
            // 1. 启动本地 UDP 代理
            NSLog("🔵 MorphProtocolPlugin: Starting local proxy...")
            if let assignedPort = morphClient?.startLocalProxy(preferredPort: UInt16(localProxyPort)) {
                self.localPort = assignedPort
                NSLog("✅ MorphProtocolPlugin: Local proxy started on port \(assignedPort)")
            } else {
                call.reject("Failed to start local UDP proxy")
                return
            }
            
            // 2. 连接到远程服务器
            NSLog("🔵 MorphProtocolPlugin: Connecting to remote server...")
            morphClient?.connectToRemote(host: host, port: UInt16(port))
            
            // 返回本地端口（WireGuard 应连接到此端口）
            call.resolve([
                "success": true,
                "message": "Connecting to \(host):\(port)",
                "localPort": Int(self.localPort)
            ])
            
        } catch {
            NSLog("❌ MorphProtocolPlugin: Failed to create client: \(error)")
            connectionStatus = "failed"
            call.reject("Failed to create MorphProtocol client: \(error.localizedDescription)")
        }
    }
    
    @objc func disconnect(_ call: CAPPluginCall) {
        NSLog("🔵 MorphProtocolPlugin: disconnect() called")
        
        morphClient?.disconnect()
        morphClient = nil
        localPort = 0
        sessionPort = 0
        connectionStatus = "disconnected"
        
        notifyListeners("statusChanged", data: [
            "status": "disconnected"
        ])
        
        call.resolve([
            "success": true,
            "message": "Disconnected"
        ])
    }
    
    @objc func getStatus(_ call: CAPPluginCall) {
        var result: [String: Any] = [
            "status": connectionStatus
        ]
        
        if localPort > 0 {
            result["localPort"] = Int(localPort)
        }
        
        if sessionPort > 0 {
            result["sessionPort"] = Int(sessionPort)
        }
        
        call.resolve(result)
    }
    
    @objc func send(_ call: CAPPluginCall) {
        guard let dataString = call.getString("data") else {
            call.reject("Missing data parameter")
            return
        }
        
        guard let data = Data(base64Encoded: dataString) else {
            call.reject("Invalid base64 data")
            return
        }
        
        guard let client = morphClient else {
            call.reject("Not connected")
            return
        }
        
        client.send(data)
        
        call.resolve([
            "success": true,
            "message": "Data sent"
        ])
    }
    
    // MARK: - Private Methods
    
    private func notifyDataReceived(_ data: Data) {
        let base64String = data.base64EncodedString()
        notifyListeners("dataReceived", data: [
            "data": base64String
        ])
    }
    
    private func handleStateChange(_ state: NWConnection.State) {
        let statusString: String
        switch state {
        case .ready:
            statusString = "connecting" // 连接就绪但还没完成握手
        case .preparing, .waiting:
            statusString = "connecting"
        case .failed:
            statusString = "failed"
            connectionStatus = "failed"
        case .cancelled:
            statusString = "disconnected"
            connectionStatus = "disconnected"
        default:
            statusString = "disconnected"
        }
        
        // 只在非 connected 状态时通知（connected 由 handshakeComplete 触发）
        if statusString != "connecting" || connectionStatus != "connected" {
            notifyListeners("statusChanged", data: [
                "status": statusString,
                "localPort": Int(localPort),
                "sessionPort": Int(sessionPort)
            ])
        }
    }
}
