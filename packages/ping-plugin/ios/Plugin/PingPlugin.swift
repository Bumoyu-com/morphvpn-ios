import Foundation
import Capacitor

@objc(PingPlugin)
public class PingPlugin: CAPPlugin {
    
    private var activePingers: [String: SwiftyPing] = [:]
    
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
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.performPing(host: host, call: call)
        }
    }
    
    private func performPing(host: String, call: CAPPluginCall) {
        var latencies: [Double] = []
        let semaphore = DispatchSemaphore(value: 0)
        var pingCount = 0
        let targetCount = 3
        
        do {
            // 创建 SwiftyPing 配置
            let configuration = PingConfiguration(interval: 0.5, with: 3)
            
            // 创建 pinger
            let pinger = try SwiftyPing(host: host, configuration: configuration, queue: DispatchQueue.global())
            
            NSLog("🏓 PingPlugin: SwiftyPing created for \(host)")
            
            // 设置观察者
            pinger.observer = { response in
                let duration = response.duration * 1000.0 // 转换为毫秒
                NSLog("🏓 PingPlugin: Received response, duration: \(String(format: "%.2f", duration)) ms")
                latencies.append(duration)
                pingCount += 1
                
                if pingCount >= targetCount {
                    pinger.stopPinging()
                    semaphore.signal()
                }
            }
            
            // 设置完成回调
            pinger.finished = { result in
                NSLog("🏓 PingPlugin: Ping finished with result")
                if pingCount < targetCount {
                    semaphore.signal()
                }
            }
            
            // 设置目标次数
            pinger.targetCount = targetCount
            
            // 开始 ping
            NSLog("🏓 PingPlugin: Starting ping to \(host)")
            try pinger.startPinging()
            
            // 等待完成（最多 10 秒）
            let timeout = DispatchTime.now() + .seconds(10)
            let result = semaphore.wait(timeout: timeout)
            
            // 停止 ping
            pinger.stopPinging()
            
            if result == .timedOut {
                NSLog("⏱️ PingPlugin: Ping operation timed out")
            }
            
        } catch {
            NSLog("❌ PingPlugin: Failed to create pinger: \(error.localizedDescription)")
        }
        
        // 计算平均值并返回结果
        DispatchQueue.main.async {
            let result: [String: Any]
            if latencies.isEmpty {
                NSLog("🏓 PingPlugin: All pings failed, returning null")
                result = ["latency": NSNull()]
            } else {
                let average = latencies.reduce(0, +) / Double(latencies.count)
                let avgInt = Int(round(average))
                NSLog("🏓 PingPlugin: Average latency: \(avgInt) ms (from \(latencies.count) responses)")
                result = ["latency": avgInt]
            }
            call.resolve(result)
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
