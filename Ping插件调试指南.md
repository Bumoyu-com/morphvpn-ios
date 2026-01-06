# Ping 插件调试指南

## 问题分析

根据日志显示，所有 ping 请求都超时返回 null。已添加详细的调试日志来诊断问题。

## 已添加的调试日志

### PingPlugin.swift 日志

```
🏓 PingPlugin: Received ping request for: [address]
🏓 PingPlugin: Extracted host: [host]
🏓 PingPlugin: Ping attempt 1/3 to [host]
🏓 PingPlugin: Ping 1 succeeded: [latency] ms
🏓 PingPlugin: Ping 1 failed
🏓 PingPlugin: All pings failed, returning null
🏓 PingPlugin: Average latency: [avg] ms
```

### ICMPPinger.swift 日志

```
🏓 ICMPPinger: Initialized for host: [host], timeout: [timeout]s
🏓 ICMPPinger: Starting ping to [host]
🏓 ICMPPinger: Resolving host: [host]
🏓 ICMPPinger: Resolved [host] to [ip]
🏓 ICMPPinger: Creating socket
🏓 ICMPPinger: Socket created successfully (fd: [fd])
🏓 ICMPPinger: Set receive timeout to [timeout]s
🏓 ICMPPinger: Using identifier: [id], sequence: [seq]
🏓 ICMPPinger: Created ICMP packet, size: [size] bytes
🏓 ICMPPinger: Sending packet ([size] bytes)
🏓 ICMPPinger: Sent [sent] bytes successfully
🏓 ICMPPinger: Waiting for reply (timeout: [timeout]s)
🏓 ICMPPinger: Received [received] bytes
🏓 ICMPPinger: ICMP type: [type], code: [code]
🏓 ICMPPinger: Identifier: [id] (expected: [expected])
🏓 ICMPPinger: Sequence: [seq] (expected: [expected])
✅ ICMPPinger: Valid reply received
✅ ICMPPinger: Received reply, latency: [latency] ms
```

### 错误日志

```
❌ ICMPPinger: Failed to resolve host: [host]
❌ ICMPPinger: getaddrinfo failed: [error]
❌ ICMPPinger: Failed to create socket
❌ ICMPPinger: socket() failed: [error] (errno: [errno])
❌ ICMPPinger: Failed to create ICMP packet
❌ ICMPPinger: Failed to send packet
❌ ICMPPinger: sendto() failed: [error] (errno: [errno])
❌ ICMPPinger: Failed to receive reply (timeout or error)
❌ ICMPPinger: recv() failed: [error] (errno: [errno])
⏱️ ICMPPinger: recv() timeout
❌ ICMPPinger: Packet too small: [size] bytes
❌ ICMPPinger: Not an Echo Reply (type: [type])
❌ ICMPPinger: Identifier mismatch
❌ ICMPPinger: Sequence number mismatch
```

## 如何查看日志

### 方法 1: Xcode Console

1. 在 Xcode 中打开项目
2. 运行应用
3. 打开 Console 面板（View → Debug Area → Activate Console）
4. 搜索 "🏓" 或 "ICMPPinger" 或 "PingPlugin"

### 方法 2: 命令行

```bash
# 实时查看日志
xcrun simctl spawn booted log stream --predicate 'processImagePath contains "App"' --level debug

# 或者使用 grep 过滤
xcrun simctl spawn booted log stream | grep -E "🏓|ICMPPinger|PingPlugin"
```

### 方法 3: Safari Web Inspector

1. 在 Safari 中打开 Develop 菜单
2. 选择你的设备和应用
3. 查看 Console 标签页
4. 可以看到 JavaScript 层的日志

## 常见问题诊断

### 问题 1: DNS 解析失败

**日志特征:**
```
❌ ICMPPinger: Failed to resolve host: [host]
❌ ICMPPinger: getaddrinfo failed: [error]
```

**可能原因:**
- 网络未连接
- DNS 服务器不可用
- 域名不存在

**解决方法:**
- 检查设备网络连接
- 尝试使用 IP 地址而不是域名
- 检查 DNS 设置

### 问题 2: Socket 创建失败

**日志特征:**
```
❌ ICMPPinger: Failed to create socket
❌ ICMPPinger: socket() failed: [error] (errno: [errno])
```

**可能原因:**
- 权限不足（iOS 通常不会有这个问题）
- 系统资源不足

**常见 errno:**
- `EACCES (13)`: 权限被拒绝
- `EMFILE (24)`: 进程打开的文件描述符过多
- `ENFILE (23)`: 系统打开的文件描述符过多

**解决方法:**
- 确保使用 `SOCK_DGRAM` 而不是 `SOCK_RAW`
- 检查是否有其他 socket 未关闭

### 问题 3: 发送失败

**日志特征:**
```
❌ ICMPPinger: Failed to send packet
❌ ICMPPinger: sendto() failed: [error] (errno: [errno])
```

**可能原因:**
- 网络不可达
- 目标地址无效
- 防火墙阻止

**常见 errno:**
- `ENETUNREACH (51)`: 网络不可达
- `EHOSTUNREACH (65)`: 主机不可达
- `EPERM (1)`: 操作不允许

### 问题 4: 接收超时

**日志特征:**
```
⏱️ ICMPPinger: recv() timeout
❌ ICMPPinger: Failed to receive reply (timeout or error)
```

**可能原因:**
- 目标主机不响应 ICMP
- 网络延迟过高
- 防火墙阻止 ICMP 回复
- ICMP 包被丢弃

**解决方法:**
- 增加超时时间
- 尝试 ping 已知可用的服务器（如 8.8.8.8）
- 检查网络防火墙设置

### 问题 5: 收到错误的回复

**日志特征:**
```
❌ ICMPPinger: Not an Echo Reply (type: [type])
❌ ICMPPinger: Identifier mismatch
❌ ICMPPinger: Sequence number mismatch
```

**可能原因:**
- 收到其他 ICMP 消息（如 Destination Unreachable）
- 收到其他进程的 ICMP 回复
- 网络中间设备修改了包

**ICMP 类型:**
- `0`: Echo Reply（正常回复）
- `3`: Destination Unreachable
- `8`: Echo Request
- `11`: Time Exceeded

## 修复的关键问题

### 1. SOCK_DGRAM vs SOCK_RAW

iOS 上必须使用 `SOCK_DGRAM` 而不是 `SOCK_RAW`：

```swift
// ✅ 正确
socket = Darwin.socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP)

// ❌ 错误（需要 root 权限）
socket = Darwin.socket(AF_INET, SOCK_RAW, IPPROTO_ICMP)
```

### 2. IP Header 处理

使用 `SOCK_DGRAM` 时，系统会自动处理 IP header：

```swift
// ✅ 正确：SOCK_DGRAM 不包含 IP header
let icmpData = buffer.prefix(received)

// ❌ 错误：SOCK_RAW 才需要跳过 IP header
let ipHeaderLength = 20
let icmpData = buffer.subdata(in: ipHeaderLength..<received)
```

### 3. 超时设置

同时设置接收和发送超时：

```swift
// 接收超时
setsockopt(socket, SOL_SOCKET, SO_RCVTIMEO, &tv, ...)

// 发送超时
setsockopt(socket, SOL_SOCKET, SO_SNDTIMEO, &tv, ...)
```

## 测试步骤

### 1. 基本测试

```javascript
// 测试 Google DNS
const result1 = await window.PingBridge.ping('8.8.8.8');
console.log('8.8.8.8:', result1);

// 测试 Cloudflare DNS
const result2 = await window.PingBridge.ping('1.1.1.1');
console.log('1.1.1.1:', result2);
```

### 2. 域名测试

```javascript
// 测试域名解析
const result = await window.PingBridge.ping('google.com');
console.log('google.com:', result);
```

### 3. URL 测试

```javascript
// 测试 URL 解析
const result = await window.PingBridge.ping('https://www.google.com');
console.log('https://www.google.com:', result);
```

### 4. 批量测试

```javascript
const servers = [
  '8.8.8.8',
  '1.1.1.1',
  'google.com',
  'cloudflare.com'
];

const results = await window.PingBridge.pingConcurrent(servers);
console.table(results);
```

## 预期日志输出

成功的 ping 应该产生如下日志：

```
🏓 PingPlugin: Received ping request for: 8.8.8.8
🏓 PingPlugin: Extracted host: 8.8.8.8
🏓 PingPlugin: Ping attempt 1/3 to 8.8.8.8
🏓 ICMPPinger: Initialized for host: 8.8.8.8, timeout: 3.0s
🏓 ICMPPinger: Starting ping to 8.8.8.8
🏓 ICMPPinger: Resolving host: 8.8.8.8
🏓 ICMPPinger: Successfully resolved host
🏓 ICMPPinger: Resolved 8.8.8.8 to 8.8.8.8
🏓 ICMPPinger: Creating socket
🏓 ICMPPinger: Socket created successfully (fd: 3)
🏓 ICMPPinger: Set receive timeout to 3.0s
🏓 ICMPPinger: Using identifier: 12345, sequence: 54321
🏓 ICMPPinger: Created ICMP packet, size: 64 bytes
🏓 ICMPPinger: Sending packet (64 bytes)
🏓 ICMPPinger: Sent 64 bytes successfully
🏓 ICMPPinger: Waiting for reply (timeout: 3.0s)
🏓 ICMPPinger: Received 64 bytes
🏓 ICMPPinger: ICMP type: 0, code: 0
🏓 ICMPPinger: Identifier: 12345 (expected: 12345)
🏓 ICMPPinger: Sequence: 54321 (expected: 54321)
✅ ICMPPinger: Valid reply received
✅ ICMPPinger: Received reply, latency: 25.34 ms
🏓 PingPlugin: Ping 1 succeeded: 25.34 ms
[重复 2 次]
🏓 PingPlugin: Average latency: 25 ms
```

## 下一步

1. 在 Xcode 中运行应用
2. 打开 Console 查看详细日志
3. 尝试 ping `8.8.8.8`
4. 根据日志输出诊断问题
5. 如果仍然失败，请提供完整的日志输出

## 可能需要的权限

检查 `Info.plist` 是否包含网络权限：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

虽然 ICMP 不需要特殊权限，但确保应用有基本的网络访问权限。
