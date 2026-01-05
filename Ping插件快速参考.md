# Ping 插件快速参考

## ✅ 可行性

**是的，可以实现真正的 ICMP Ping！**

- 使用 iOS 原生 BSD socket + ICMP 协议
- 真正的网络层 ping，不是 HTTP 伪 ping
- 无需特殊权限

## 快速开始

### 1. 基本调用

```javascript
// 单个地址
const latency = await window.PingBridge.ping('8.8.8.8');
console.log(latency); // 25 或 null

// 批量测试（并发）
const results = await window.PingBridge.pingConcurrent([
  '8.8.8.8',
  'google.com',
  'https://cloudflare.com'
]);
```

### 2. 支持的格式

```javascript
window.PingBridge.ping('8.8.8.8');              // ✅ IP
window.PingBridge.ping('google.com');           // ✅ 域名
window.PingBridge.ping('https://google.com');   // ✅ HTTPS URL
window.PingBridge.ping('http://example.com');   // ✅ HTTP URL
```

### 3. React 使用

```typescript
function ServerPing() {
  const [latency, setLatency] = useState<number | null>(null);

  const testPing = async () => {
    const result = await window.PingBridge.ping('8.8.8.8');
    setLatency(result);
  };

  return (
    <div>
      延迟: {latency !== null ? `${latency} ms` : '超时'}
      <button onClick={testPing}>测试</button>
    </div>
  );
}
```

## API

### `ping(address: string): Promise<number | null>`

- **参数**: 地址（IP/域名/URL）
- **返回**: 延迟（毫秒）或 null（超时）
- **行为**: 自动 ping 3次，返回平均值
- **超时**: 3秒/次，总计约9秒

### `pingMultiple(addresses: string[]): Promise<Array<{address, latency}>>`

- **参数**: 地址数组
- **返回**: 结果数组
- **行为**: 顺序执行

### `pingConcurrent(addresses: string[]): Promise<Array<{address, latency}>>`

- **参数**: 地址数组
- **返回**: 结果数组
- **行为**: 并发执行（推荐）

## 技术规格

| 项目 | 值 |
|------|-----|
| 协议 | ICMP Echo Request/Reply |
| 测试次数 | 3次 |
| 超时时间 | 3秒/次 |
| 返回值 | 整数（毫秒）或 null |
| 平台支持 | iOS ✅ / Web ❌ |
| 权限要求 | 无 |

## 文件位置

- **插件源码**: `packages/ping-plugin/`
- **JS Bridge**: `public/ping-bridge.js`
- **测试页面**: `public/ping-test.html`
- **类型声明**: `src/types/ping-bridge.d.ts`
- **Hook 示例**: `src/hooks/usePing.example.ts`

## 测试

访问测试页面：
```
http://localhost:5173/ping-test.html
```

## 常见问题

**Q: 为什么返回 null？**
A: 超时（3秒）、网络不可达、防火墙阻止 ICMP

**Q: 和 HTTP 请求有什么区别？**
A: ICMP 是网络层协议，测量纯网络延迟；HTTP 是应用层，包含服务器处理时间

**Q: 可以在浏览器中使用吗？**
A: 不可以，浏览器无法发送 ICMP 包

**Q: 需要特殊权限吗？**
A: iOS 上不需要

## 示例代码

### 服务器选择器

```typescript
function ServerSelector() {
  const servers = [
    { id: 1, name: 'US West', address: 'us-west.example.com' },
    { id: 2, name: 'US East', address: 'us-east.example.com' },
    { id: 3, name: 'EU', address: 'eu.example.com' },
  ];

  const [results, setResults] = useState([]);

  const testServers = async () => {
    const addresses = servers.map(s => s.address);
    const pingResults = await window.PingBridge.pingConcurrent(addresses);
    
    const combined = servers.map((server, i) => ({
      ...server,
      latency: pingResults[i].latency
    }));
    
    setResults(combined.sort((a, b) => 
      (a.latency || 9999) - (b.latency || 9999)
    ));
  };

  return (
    <div>
      <button onClick={testServers}>测试所有服务器</button>
      {results.map(server => (
        <div key={server.id}>
          {server.name}: {
            server.latency !== null 
              ? `${server.latency} ms` 
              : '不可用'
          }
        </div>
      ))}
    </div>
  );
}
```

### 实时监控

```typescript
function RealtimeMonitor() {
  const [latency, setLatency] = useState<number | null>(null);

  useEffect(() => {
    const interval = setInterval(async () => {
      const result = await window.PingBridge.ping('8.8.8.8');
      setLatency(result);
    }, 10000); // 每10秒测试一次

    return () => clearInterval(interval);
  }, []);

  return (
    <div>
      当前延迟: {latency !== null ? `${latency} ms` : '测试中...'}
    </div>
  );
}
```

## 总结

✅ **完全满足需求**

1. ✅ 真正的 ICMP ping
2. ✅ 支持 HTTP/HTTPS URL 和 IP
3. ✅ Ping 3次取平均值
4. ✅ 返回整数毫秒或 null
5. ✅ 3秒超时
6. ✅ 独立 JS 调用（window.PingBridge）
7. ✅ HTML 引用 ping-bridge.js

插件已完成并可直接使用！
