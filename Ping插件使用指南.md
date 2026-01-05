# Ping 插件使用指南

## ✅ 可行性确认

**是的，可以实现真正的 ICMP Ping！**

本插件使用 iOS 原生的 BSD socket 和 ICMP 协议，实现了真正的网络层 ping，而不是应用层的伪 ping（如 HTTP 请求）。

## 技术实现

- **协议**：ICMP Echo Request/Reply
- **实现方式**：BSD socket + ICMP
- **测试次数**：自动 ping 3次
- **超时时间**：每次 3 秒
- **返回值**：平均延迟（毫秒整数）或 null（超时）

## 插件特性

1. ✅ **真正的 ICMP Ping**：使用网络层协议，不是 HTTP 请求
2. ✅ **支持多种格式**：IP 地址、域名、HTTP/HTTPS URL
3. ✅ **自动平均值**：ping 3次并计算平均延迟
4. ✅ **超时控制**：3秒超时，超时返回 null
5. ✅ **独立调用**：通过 `window.PingBridge` 调用，不依赖 React
6. ✅ **无需权限**：iOS 上 ICMP ping 不需要特殊权限

## 安装

插件已集成到项目中：

```bash
# 已完成
npm install --legacy-peer-deps
npx cap sync ios
```

## 使用方法

### 1. 基本用法

```javascript
// 单个地址 ping
const latency = await window.PingBridge.ping('8.8.8.8');
console.log('延迟:', latency, 'ms'); // 延迟: 25 ms 或 null（超时）
```

### 2. 支持的地址格式

```javascript
// IP 地址
await window.PingBridge.ping('8.8.8.8');

// 域名
await window.PingBridge.ping('google.com');

// HTTPS URL（自动提取主机名）
await window.PingBridge.ping('https://google.com');

// HTTP URL（自动提取主机名）
await window.PingBridge.ping('http://example.com/path');
```

### 3. 批量测试（顺序执行）

```javascript
const results = await window.PingBridge.pingMultiple([
  '8.8.8.8',
  'google.com',
  'https://cloudflare.com'
]);

console.log(results);
// [
//   { address: '8.8.8.8', latency: 25 },
//   { address: 'google.com', latency: 30 },
//   { address: 'https://cloudflare.com', latency: 15 }
// ]
```

### 4. 并发测试（同时执行，更快）

```javascript
const results = await window.PingBridge.pingConcurrent([
  '8.8.8.8',
  '1.1.1.1',
  'google.com'
]);

// 并发执行，总耗时约等于单次 ping 时间（约9秒）
// 而不是顺序执行的 3倍时间（约27秒）
```

### 5. 在 React 中使用

虽然设计为独立调用，但也可以在 React 组件中使用：

```typescript
import { useEffect, useState } from 'react';

function ServerPingTest() {
  const [servers, setServers] = useState([
    { address: '8.8.8.8', name: 'Google DNS', latency: null },
    { address: '1.1.1.1', name: 'Cloudflare DNS', latency: null },
  ]);

  const testServers = async () => {
    const results = await window.PingBridge.pingConcurrent(
      servers.map(s => s.address)
    );

    setServers(servers.map((server, index) => ({
      ...server,
      latency: results[index].latency
    })));
  };

  useEffect(() => {
    testServers();
  }, []);

  return (
    <div>
      <h2>服务器延迟测试</h2>
      {servers.map(server => (
        <div key={server.address}>
          {server.name}: {
            server.latency !== null 
              ? `${server.latency} ms` 
              : '超时'
          }
        </div>
      ))}
      <button onClick={testServers}>重新测试</button>
    </div>
  );
}
```

## API 文档

### `window.PingBridge.ping(address: string): Promise<number | null>`

执行单次 ping 测试（自动 ping 3次并计算平均值）。

**参数：**
- `address` (string): 目标地址
  - 支持 IP 地址：`'8.8.8.8'`
  - 支持域名：`'google.com'`
  - 支持 URL：`'https://google.com'`

**返回值：**
- `number`: 平均延迟（毫秒整数）
- `null`: 超时或失败

**示例：**
```javascript
const latency = await window.PingBridge.ping('8.8.8.8');
if (latency !== null) {
  console.log(`延迟: ${latency} ms`);
} else {
  console.log('超时');
}
```

### `window.PingBridge.pingMultiple(addresses: string[]): Promise<Array<{address: string, latency: number|null}>>`

顺序 ping 多个地址。

**参数：**
- `addresses` (string[]): 地址数组

**返回值：**
- Array<{address: string, latency: number|null}>

**示例：**
```javascript
const results = await window.PingBridge.pingMultiple([
  '8.8.8.8',
  'google.com'
]);
```

### `window.PingBridge.pingConcurrent(addresses: string[]): Promise<Array<{address: string, latency: number|null}>>`

并发 ping 多个地址（推荐用于多个地址测试）。

**参数：**
- `addresses` (string[]): 地址数组

**返回值：**
- Array<{address: string, latency: number|null}>

**示例：**
```javascript
const results = await window.PingBridge.pingConcurrent([
  '8.8.8.8',
  '1.1.1.1',
  'google.com'
]);
```

## 测试页面

访问测试页面验证功能：

```
http://localhost:5173/ping-test.html
```

测试页面提供：
- 单个地址测试
- 批量测试（顺序）
- 并发测试

## 技术细节

### ICMP 实现原理

1. **DNS 解析**：将域名/URL 解析为 IP 地址
2. **创建 Socket**：使用 `SOCK_DGRAM` + `IPPROTO_ICMP`
3. **构建 ICMP 包**：
   - Type: 8 (Echo Request)
   - Code: 0
   - Identifier: 进程 ID
   - Sequence Number: 随机数
   - Checksum: 自动计算
4. **发送请求**：通过 socket 发送 ICMP Echo Request
5. **接收回复**：等待 ICMP Echo Reply
6. **计算延迟**：记录发送和接收时间差

### 为什么是真正的 Ping？

| 特性 | 本插件 (ICMP) | HTTP 请求 (伪ping) |
|------|---------------|-------------------|
| 协议层级 | 网络层 (Layer 3) | 应用层 (Layer 7) |
| 协议类型 | ICMP | HTTP/HTTPS |
| 测量内容 | 网络往返时间 | HTTP 响应时间 |
| 受服务器影响 | ❌ 否 | ✅ 是（服务器处理时间）|
| 需要 Web 服务 | ❌ 否 | ✅ 是 |
| 标准 ping 工具 | ✅ 相同原理 | ❌ 不同 |

## 注意事项

1. **网络要求**：设备需要联网
2. **防火墙**：某些网络可能阻止 ICMP 包
3. **超时时间**：单次 ping 超时 3 秒，总计约 9 秒
4. **Web 平台**：不支持（浏览器无法发送 ICMP 包）
5. **权限**：iOS 上无需特殊权限

## 故障排查

### 问题：返回 null

**可能原因：**
1. 目标主机不可达
2. 网络防火墙阻止 ICMP
3. DNS 解析失败
4. 超时（3秒）

**解决方法：**
- 检查网络连接
- 尝试 ping 其他地址（如 8.8.8.8）
- 检查防火墙设置

### 问题：延迟很高

**可能原因：**
1. 网络质量差
2. 目标服务器距离远
3. 网络拥塞

**解决方法：**
- 多次测试取平均值
- 测试多个服务器对比

## 文件结构

```
packages/ping-plugin/
├── ios/Plugin/
│   ├── PingPlugin.swift       # Capacitor 插件接口
│   ├── PingPlugin.m           # Objective-C 桥接
│   └── ICMPPinger.swift       # ICMP ping 实现
├── src/
│   ├── definitions.ts         # TypeScript 类型定义
│   ├── index.ts              # 插件导出
│   └── web.ts                # Web 平台占位
├── package.json
├── tsconfig.json
├── rollup.config.js
└── MorphvpnCapacitorPing.podspec

public/
├── ping-bridge.js            # 独立 JS 调用层
└── ping-test.html            # 测试页面
```

## 构建和发布

```bash
# 构建插件
cd packages/ping-plugin
npm run build

# 同步到 iOS
cd ../..
npx cap sync ios
```

## 总结

✅ **可以实现真正的 ICMP Ping**

本插件满足所有需求：
1. ✅ 真正的 ICMP ping，不是伪 ping
2. ✅ 接受 HTTP/HTTPS URL 和 IP 地址
3. ✅ Ping 3次计算平均值
4. ✅ 返回整数毫秒，超时返回 null
5. ✅ 3秒超时
6. ✅ 独立 JS 文件调用（window.PingBridge）
7. ✅ HTML 引用 ping-bridge.js

插件已完全实现并集成到项目中，可以直接使用！
