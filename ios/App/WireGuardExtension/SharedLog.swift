//
//  SharedLog.swift
//  WireGuardExtension
//
//  通过 App Group 共享容器写日志，App 进程可读取 Extension 进程的日志。
//

import Foundation

class SharedLog {
    static let shared = SharedLog()
    
    private let fileManager = FileManager.default
    private let maxSize = 100 * 1024  // 100KB，超过后截断
    private var logURL: URL?
    
    private init() {
        if let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.morphvpn.app.wireguard") {
            logURL = containerURL.appendingPathComponent("extension_log.txt")
        }
    }
    
    func log(_ message: String) {
        guard let url = logURL else { return }
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "[\(timestamp)] \(message)\n"
        
        // 同时输出到 NSLog（Xcode 设备日志可见）
        NSLog("📋 EXT: \(message)")
        
        // 写入共享文件
        if fileManager.fileExists(atPath: url.path) {
            // 检查文件大小，超过上限则截断
            if let attrs = try? fileManager.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? Int, size > maxSize {
                try? "--- LOG TRUNCATED ---\n".write(to: url, atomically: true, encoding: .utf8)
            }
            
            if let handle = try? FileHandle(forWritingTo: url) {
                handle.seekToEndOfFile()
                if let data = line.data(using: .utf8) {
                    handle.write(data)
                }
                handle.closeFile()
            }
        } else {
            try? line.write(to: url, atomically: true, encoding: .utf8)
        }
    }
    
    /// 清空日志（App 端调用）
    static func clear() {
        let fm = FileManager.default
        if let containerURL = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.com.morphvpn.app.wireguard") {
            let url = containerURL.appendingPathComponent("extension_log.txt")
            try? "".write(to: url, atomically: true, encoding: .utf8)
        }
    }
    
    /// 读取日志（App 端调用）
    static func read() -> String {
        let fm = FileManager.default
        if let containerURL = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.com.morphvpn.app.wireguard") {
            let url = containerURL.appendingPathComponent("extension_log.txt")
            return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        }
        return ""
    }
}
