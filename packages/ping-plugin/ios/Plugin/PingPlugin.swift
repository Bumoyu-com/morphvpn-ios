import Foundation
import Capacitor

@objc(PingPlugin)
public class PingPlugin: CAPPlugin {
    
    @objc func ping(_ call: CAPPluginCall) {
        guard let address = call.getString("address") else {
            NSLog("🏓 PingPlugin: Missing address parameter")
            call.reject("Missing address parameter")
            return
        }
        
        NSLog("🏓 PingPlugin: Received ping request for: \(address)")
        
        // 提取主机名（支持 URL、IP、域名）
        let host = extractHost(from: address)
        NSLog("🏓 PingPlugin: Extracted host: \(host)")
        
        // 在后台线程执行 ping
        DispatchQueue.global(qos: .userInitiated).async {
            let pinger = ICMPPinger(host: host, timeout: 3.0)
            
            var latencies: [Double] = []
            
            // Ping 3次
            for i in 0..<3 {
                NSLog("🏓 PingPlugin: Ping attempt \(i+1)/3 to \(host)")
                if let latency = pinger.ping() {
                    NSLog("🏓 PingPlugin: Ping \(i+1) succeeded: \(latency) ms")
                    latencies.append(latency)
                } else {
                    NSLog("🏓 PingPlugin: Ping \(i+1) failed")
                }
            }
            
            // 计算平均值
            let result: [String: Any]
            if latencies.isEmpty {
                NSLog("🏓 PingPlugin: All pings failed, returning null")
                result = ["latency": NSNull()]
            } else {
                let average = latencies.reduce(0, +) / Double(latencies.count)
                let avgInt = Int(round(average))
                NSLog("🏓 PingPlugin: Average latency: \(avgInt) ms")
                result = ["latency": avgInt]
            }
            
            DispatchQueue.main.async {
                call.resolve(result)
            }
        }
    }
    
    private func extractHost(from address: String) -> String {
        // 尝试解析为 URL
        if let url = URL(string: address), let host = url.host {
            return host
        }
        
        // 移除协议前缀
        var cleaned = address
        if cleaned.hasPrefix("http://") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("https://") {
            cleaned = String(cleaned.dropFirst(8))
        }
        
        // 移除路径和端口
        if let slashIndex = cleaned.firstIndex(of: "/") {
            cleaned = String(cleaned[..<slashIndex])
        }
        if let colonIndex = cleaned.firstIndex(of: ":") {
            cleaned = String(cleaned[..<colonIndex])
        }
        
        return cleaned
    }
}
