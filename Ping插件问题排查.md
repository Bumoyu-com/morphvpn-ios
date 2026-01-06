# Ping 插件问题排查清单

## 当前状态

所有 ping 请求都返回 null（超时）。已添加详细日志，需要查看 Xcode Console 输出来诊断具体问题。

## 快速排查步骤

### 1. 查看 Xcode 日志 ⭐ 最重要

```bash
# 在 Xcode 中
1. 打开项目
2. 运行应用（Command + R）
3. 打开 Console（Command + Shift + Y）
4. 在搜索框输入: 🏓
5. 执行一次 ping
6. 查看完整日志输出
```

**关键日志点:**
- ✅ `Socket created successfully` - Socket 创建成功
- ✅ `Sent X bytes successfully` - 数据发送成功
- ⏱️ `recv() timeout` - 接收超时（最可能的问题）
- ❌ `Failed to resolve host` - DNS 解析失败
- ❌ `socket() failed` - Socket 创建失败

### 2. 检查网络连接

```javascript
// 在浏览器 Console 中测试
fetch('https://www.google.com')
  .then(() => console.log('✅ 网络正常'))
  .catch(() => console.log('❌ 网络异常'));
```

### 3. 测试已知可用的服务器

```javascript
// Google DNS（通常响应 ICMP）
await window.PingBridge.ping('8.8.8.8');

// Cloudflare DNS
await window.PingBridge.ping('1.1.1.1');

// 如果这些都失败，说明是代码问题
// 如果成功，说明是目标服务器不响应 ICMP
```

## 可能的问题和解决方案

### 问题 A: iOS 模拟器限制 ⚠️ 最可能

**症状:**
- 所有 ping 都超时
- 日志显示发送成功但接收超时
- 在真机上可能正常工作

**原因:**
iOS 模拟器可能不支持 ICMP 或有网络限制。

**解决方案:**
```
在真实 iOS 设备上测试！
```

**验证方法:**
1. 连接 iPhone/iPad
2. 在 Xcode 中选择真实设备
3. 运行应用并测试

### 问题 B: SOCK_DGRAM 限制

**症状:**
- Socket 创建成功
- 发送成功
- 接收超时

**原因:**
`SOCK_DGRAM` + `IPPROTO_ICMP` 在某些 iOS 版本上可能有限制。

**解决方案:**
可能需要使用 CFSocket 或 Network.framework 的更高级 API。

### 问题 C: 防火墙/网络策略

**症状:**
- 特定网络下失败
- 某些地址可以 ping 通，某些不行

**原因:**
- 企业网络阻止 ICMP
- VPN 干扰
- 防火墙规则

**解决方案:**
- 切换到移动网络测试
- 关闭 VPN
- 尝试不同的网络环境

### 问题 D: 目标服务器不响应 ICMP

**症状:**
- 某些服务器超时
- 其他服务器正常

**原因:**
许多服务器配置为不响应 ICMP ping（安全策略）。

**已知不响应 ICMP 的服务器:**
- 许多 CDN 节点
- 某些云服务器
- 配置了防火墙的服务器

**解决方案:**
使用已知响应 ICMP 的服务器测试：
- `8.8.8.8` (Google DNS)
- `1.1.1.1` (Cloudflare DNS)
- `208.67.222.222` (OpenDNS)

## 替代方案

如果 ICMP ping 在 iOS 上确实无法工作，可以考虑以下替代方案：

### 方案 1: TCP Connect 测试

测量 TCP 连接建立时间：

```swift
func tcpPing(host: String, port: Int) -> Double? {
    let startTime = Date()
    
    var addr = sockaddr_in()
    addr.sin_family = sa_family_t(AF_INET)
    addr.sin_port = UInt16(port).bigEndian
    inet_pton(AF_INET, host, &addr.sin_addr)
    
    let sock = socket(AF_INET, SOCK_STREAM, 0)
    defer { close(sock) }
    
    // 设置非阻塞
    fcntl(sock, F_SETFL, O_NONBLOCK)
    
    // 尝试连接
    withUnsafePointer(to: &addr) { ptr in
        ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
            connect(sock, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
        }
    }
    
    // 使用 select 等待连接完成
    var writefds = fd_set()
    // ... select 逻辑 ...
    
    let latency = Date().timeIntervalSince(startTime) * 1000.0
    return latency
}
```

**优点:**
- 不需要特殊权限
- 更可靠
- 可以测试特定端口

**缺点:**
- 不是真正的 ping
- 需要目标有开放端口
- 包含 TCP 握手时间

### 方案 2: HTTP HEAD 请求

```swift
func httpPing(url: String) async -> Double? {
    let startTime = Date()
    
    var request = URLRequest(url: URL(string: url)!)
    request.httpMethod = "HEAD"
    request.timeoutInterval = 3.0
    
    do {
        let (_, _) = try await URLSession.shared.data(for: request)
        let latency = Date().timeIntervalSince(startTime) * 1000.0
        return latency
    } catch {
        return nil
    }
}
```

**优点:**
- 简单可靠
- 不需要特殊权限
- 适用于 Web 服务器

**缺点:**
- 不是网络层测试
- 包含 HTTP 处理时间
- 需要目标是 Web 服务器

### 方案 3: 使用 Network.framework

```swift
import Network

func networkPing(host: String) {
    let connection = NWConnection(
        host: NWEndpoint.Host(host),
        port: .init(integerLiteral: 0),
        using: .udp
    )
    
    connection.start(queue: .global())
    
    // 监听状态变化
    connection.stateUpdateHandler = { state in
        switch state {
        case .ready:
            // 连接就绪
            break
        case .failed(let error):
            // 连接失败
            break
        default:
            break
        }
    }
}
```

## 调试命令

### 在 Mac 上测试 ICMP

```bash
# 测试 ICMP 是否可达
ping -c 3 8.8.8.8

# 查看路由
traceroute 8.8.8.8

# 测试 DNS 解析
nslookup google.com
```

### 检查 iOS 设备网络

```bash
# 查看设备日志
xcrun simctl spawn booted log stream --predicate 'subsystem contains "com.apple.network"'

# 查看网络接口
ifconfig
```

## 下一步行动

### 立即执行:

1. ✅ **在 Xcode Console 查看日志**
   - 运行应用
   - 执行 ping
   - 复制完整日志

2. ✅ **在真实设备上测试**
   - 连接 iPhone/iPad
   - 运行应用
   - 测试 `8.8.8.8`

3. ✅ **测试网络连接**
   - 确认设备联网
   - 测试浏览器访问
   - 尝试不同网络

### 如果仍然失败:

1. 提供完整的 Xcode Console 日志
2. 说明测试环境（模拟器/真机，iOS 版本）
3. 说明网络环境（WiFi/移动网络）
4. 考虑使用替代方案（TCP/HTTP）

## 预期结果

### 成功的情况:

```
🏓 ICMPPinger: Socket created successfully (fd: 3)
🏓 ICMPPinger: Sent 64 bytes successfully
🏓 ICMPPinger: Received 64 bytes
✅ ICMPPinger: Valid reply received
✅ ICMPPinger: Received reply, latency: 25.34 ms
```

### 失败的情况:

```
🏓 ICMPPinger: Socket created successfully (fd: 3)
🏓 ICMPPinger: Sent 64 bytes successfully
🏓 ICMPPinger: Waiting for reply (timeout: 3.0s)
⏱️ ICMPPinger: recv() timeout
❌ ICMPPinger: Failed to receive reply (timeout or error)
```

## 总结

最可能的问题是 **iOS 模拟器不支持 ICMP**。请在真实设备上测试，并查看 Xcode Console 的详细日志输出。
