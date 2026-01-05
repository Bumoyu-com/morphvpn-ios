import Foundation
import Capacitor

@objc(PingPlugin)
public class PingPlugin: CAPPlugin {
    
    @objc func ping(_ call: CAPPluginCall) {
        guard let address = call.getString("address") else {
            call.reject("Missing address parameter")
            return
        }
        
        // 提取主机名（支持 URL、IP、域名）
        let host = extractHost(from: address)
        
        // 在后台线程执行 ping
        DispatchQueue.global(qos: .userInitiated).async {
            let pinger = ICMPPinger(host: host, timeout: 3.0)
            
            var latencies: [Double] = []
            
            // Ping 3次
            for _ in 0..<3 {
                if let latency = pinger.ping() {
                    latencies.append(latency)
                }
            }
            
            // 计算平均值
            let result: [String: Any]
            if latencies.isEmpty {
                result = ["latency": NSNull()]
            } else {
                let average = latencies.reduce(0, +) / Double(latencies.count)
                result = ["latency": Int(round(average))]
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
