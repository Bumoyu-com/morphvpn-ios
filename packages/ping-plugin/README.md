# @morphvpn/capacitor-ping

原生 ICMP Ping 插件，支持 iOS 平台。

## 特性

- ✅ **真正的 ICMP Ping**：使用 BSD socket 和 ICMP 协议，不是应用层的伪 ping
- ✅ **自动平均值**：自动 ping 3次并计算平均延迟
- ✅ **超时控制**：每次 ping 超时时间为 3 秒
- ✅ **灵活输入**：支持 IP 地址、域名、HTTP/HTTPS URL
- ✅ **独立调用**：通过 `window.PingBridge` 调用，不依赖 React

## 安装

```bash
npm install @morphvpn/capacitor-ping
npx cap sync
```

## 使用方法

### 1. 在 HTML 中引入 JS Bridge

```html
<script src="/ping-bridge.js"></script>
```

### 2. 使用 window.PingBridge 调用

```javascript
// 单个地址 ping
const latency = await window.PingBridge.ping('8.8.8.8');
console.log('延迟:', latency, 'ms'); // 延迟: 25 ms 或 null（超时）

// 支持多种格式
await window.PingBridge.ping('8.8.8.8');           // IP 地址
await window.PingBridge.ping('google.com');        // 域名
await window.PingBridge.ping('https://google.com'); // HTTPS URL
await window.PingBridge.ping('http://example.com'); // HTTP URL

// 批量 ping（顺序执行）
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

// 并发 ping（同时执行）
const results = await window.PingBridge.pingConcurrent([
  '8.8.8.8',
  '1.1.1.1',
  'google.com'
]);
```

### 3. 在 React 中使用（可选）

虽然设计为独立调用，但也可以在 React 中使用：

```typescript
import { useEffect, useState } from 'react';

function PingTest() {
  const [latency, setLatency] = useState<number | null>(null);

  useEffect(() => {
    async function testPing() {
      const result = await window.PingBridge.ping('8.8.8.8');
      setLatency(result);
    }
    testPing();
  }, []);

  return (
    <div>
      延迟: {latency !== null ? `${latency} ms` : '超时'}
    </div>
  );
}
```

## API 说明

### `PingBridge.ping(address: string): Promise<number | null>`

执行 ping 测试。

- **参数**：
  - `address`: 目标地址（IP、域名、HTTP/HTTPS URL）
- **返回值**：
  - `number`: 平均延迟（毫秒）
  - `null`: 超时或失败

### `PingBridge.pingMultiple(addresses: string[]): Promise<Array<{address: string, latency: number|null}>>`

顺序 ping 多个地址。

### `PingBridge.pingConcurrent(addresses: string[]): Promise<Array<{address: string, latency: number|null}>>`

并发 ping 多个地址（更快）。

## 技术细节

- 使用 ICMP Echo Request/Reply 协议
- 每次测试 ping 3次，计算平均值
- 单次超时时间：3 秒
- 总超时时间：约 9 秒（3次 × 3秒）
- 支持 IPv4

## 注意事项

1. **iOS 权限**：ICMP ping 不需要特殊权限
2. **网络要求**：需要设备联网
3. **防火墙**：某些网络可能阻止 ICMP 包
4. **Web 平台**：不支持，返回 `null`

## 构建

```bash
cd packages/ping-plugin
npm install
npm run build
```

## 许可证

MIT
