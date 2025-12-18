import Foundation
import Capacitor

/**
 * MorphProtocol Capacitor Plugin
 * 提供独立的 MorphProtocol UDP 连接功能
 */
@objc(MorphProtocolPlugin)
public class MorphProtocolPlugin: CAPPlugin {
    private var morphClient: MorphUDPClient?
    
    @objc func connect(_ call: CAPPluginCall) {
        NSLog("🔵 MorphProtocolPlugin: connect() called")
        
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
        
        let obfuscationLayer = call.getInt("obfuscationLayer") ?? 3
        let paddingLength = call.getInt("paddingLength") ?? 8
        let templateType = call.getInt("templateType") ?? 1
        
        NSLog("🔵 MorphProtocolPlugin: Connecting to \(host):\(port)")
        NSLog("🔵 MorphProtocolPlugin: Layer=\(obfuscationLayer), Padding=\(paddingLength), Template=\(templateType)")
        
        do {
            // 创建 MorphUDPClient
            let template = TemplateType(rawValue: UInt8(templateType))
            morphClient = try MorphUDPClient(
                encryptionKey: encryptionKey,
                obfuscationLayer: obfuscationLayer,
                paddingLength: paddingLength,
                templateType: template
            )
            
            // 设置回调
            morphClient?.onReceive = { [weak self] data in
                self?.notifyDataReceived(data)
            }
            
            morphClient?.onStateChange = { [weak self] state in
                self?.notifyStatusChanged(state)
            }
            
            morphClient?.onError = { [weak self] error in
                NSLog("❌ MorphProtocolPlugin: Error: \(error)")
            }
            
            // 连接
            morphClient?.connect(host: host, port: UInt16(port))
            
            call.resolve([
                "success": true,
                "message": "Connecting to \(host):\(port)"
            ])
            
        } catch {
            NSLog("❌ MorphProtocolPlugin: Failed to create client: \(error)")
            call.reject("Failed to create MorphProtocol client: \(error.localizedDescription)")
        }
    }
    
    @objc func disconnect(_ call: CAPPluginCall) {
        NSLog("🔵 MorphProtocolPlugin: disconnect() called")
        
        morphClient?.disconnect()
        morphClient = nil
        
        call.resolve([
            "success": true,
            "message": "Disconnected"
        ])
    }
    
    @objc func getStatus(_ call: CAPPluginCall) {
        // 返回当前状态
        let status: String
        if morphClient != nil {
            status = "connected"
        } else {
            status = "disconnected"
        }
        
        call.resolve([
            "status": status
        ])
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
    
    private func notifyStatusChanged(_ state: NWConnection.State) {
        let statusString: String
        switch state {
        case .ready:
            statusString = "connected"
        case .preparing, .waiting:
            statusString = "connecting"
        case .failed:
            statusString = "failed"
        case .cancelled:
            statusString = "disconnected"
        default:
            statusString = "disconnected"
        }
        
        notifyListeners("statusChanged", data: [
            "status": statusString
        ])
    }
}
