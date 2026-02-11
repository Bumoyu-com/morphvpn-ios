import Foundation

/// 通过 App Group 共享容器写日志，App 进程可读取 Extension 进程的日志。
class SharedLog {
    static let shared = SharedLog()

    private let fileManager = FileManager.default
    private let maxSize = 100 * 1024  // 100KB
    private var logURL: URL?
    
    // 复用 DateFormatter，避免每次 log 都创建新实例（DateFormatter 是重量级对象）
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    private init() {
        if let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.morphvpn.app.wireguard") {
            logURL = containerURL.appendingPathComponent("extension_log.txt")
        }
    }

    func log(_ message: String) {
        guard let url = logURL else { return }

        let timestamp = formatter.string(from: Date())
        let line = "[\(timestamp)] \(message)\n"

        // 写入共享文件
        if fileManager.fileExists(atPath: url.path) {
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
