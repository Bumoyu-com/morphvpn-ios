# SwiftyPing 安装使用指南

## 📋 目录

1. [安装方法](#安装方法)
2. [使用方法](#使用方法)
3. [测试步骤](#测试步骤)
4. [故障排查](#故障排查)
5. [API 参考](#api-参考)

---

## 安装方法

### ✅ 已完成的集成

插件已经完全集成，无需额外安装步骤。以下是已完成的工作：

#### 1. SwiftyPing 库集成

```bash
# 已下载 SwiftyPing.swift 到插件目录
packages/ping-plugin/ios/Plugin/SwiftyPing.swift (34KB)
```

#### 2. 插件更新

```bash
# PingPlugin.swift 已更新使用 SwiftyPing
packages/ping-plugin/ios/Plugin/PingPlugin.swift
```

#### 3. 构建和同步

```bash
# 已执行
npm run build
npx cap sync ios
```

### 🔍 验证安装

检查文件是否存在：

```bash
# 检查 SwiftyPing
ls -lh packages/ping-plugin/ios/Plugin/SwiftyPing.swift

# 检查插件文件
ls -lh packages/ping-plugin/ios/Plugin/
```

预期输出：

```
-rw-r--r-- 1 user user  153 PingPlugin.m
-rw-r--r-- 1 user user 4.4K PingPlugin.swift
-rw-r--r-- 1 user user  34K SwiftyPing.swift
```

---

## 使用方法

### 1. JavaScript/TypeScript 调用

#### 基本用法

```javascript
// 单个地址 ping
const latency = await window.PingBridge.ping('8.8.8.8');

if (latency !== null) {
    console.log(`延迟: ${latency} ms`);
} else {
    console.log('超时或失败');
}
```

#### 支持的地址格式

```javascript
// IP 地址
await window.PingBridge.ping('8.8.8.8');

// 域名
await window.PingBridge.ping('google.com');

// HTTP URL
await window.PingBridge.ping('http://example.com');

// HTTPS URL
await window.PingBridge.ping('https://google.com');
```

#### 批量测试

```javascript
// 顺序执行
const results = await window.PingBridge.pingMultiple([
    '8.8.8.8',
    '1.1.1.1',
    'google.com'
]);

results.forEach(result => {
    console.log(`${result.address}: ${result.latency ?? '超时'} ms`);
});
```

#### 并发测试（推荐）

```javascript
// 同时执行，更快
const results = await window.PingBridge.pingConcurrent([
    '8.8.8.8',
    '1.1.1.1',
    'google.com',
    'cloudflare.com'
]);

// 按延迟排序
const sorted = results
    .filter(r => r.latency !== null)
    .sort((a, b) => a.latency - b.latency);

console.log('最快的服务器:', sorted[0]);
```

### 2. React 组件使用

#### 简单示例

```typescript
import { useState } from 'react';
import { message } from 'antd';

function PingTest() {
    const [address, setAddress] = useState('8.8.8.8');
    const [result, setResult] = useState<number | null>(null);

    const handlePing = async () => {
        message.loading('测试中...', 0);
        
        try {
            const latency = await window.PingBridge.ping(address);
            setResult(latency);
            
            message.destroy();
            if (latency !== null) {
                message.success(`延迟: ${latency} ms`);
            } else {
                message.error('超时或失败');
            }
        } catch (error) {
            message.destroy();
            message.error('测试失败');
        }
    };

    return (
        <div>
            <input 
                value={address}
                onChange={e => setAddress(e.target.value)}
                placeholder="输入地址"
            />
            <button onClick={handlePing}>测试</button>
            {result !== null && <p>延迟: {result} ms</p>}
        </div>
    );
}
```

#### 服务器选择器

```typescript
function ServerSelector() {
    const servers = [
        { id: 1, name: 'US West', address: 'us-west.example.com' },
        { id: 2, name: 'US East', address: 'us-east.example.com' },
        { id: 3, name: 'EU', address: 'eu.example.com' },
    ];

    const [results, setResults] = useState([]);

    const testServers = async () => {
        message.loading('测试所有服务器...', 0);
        
        const addresses = servers.map(s => s.address);
        const pingResults = await window.PingBridge.pingConcurrent(addresses);
        
        const combined = servers.map((server, i) => ({
            ...server,
            latency: pingResults[i].latency
        }));
        
        // 按延迟排序
        const sorted = combined.sort((a, b) => 
            (a.latency ?? 9999) - (b.latency ?? 9999)
        );
        
        setResults(sorted);
        message.destroy();
        message.success('测试完成');
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

### 3. LoginPage 测试界面

已在 LoginPage 中集成完整的测试界面：

#### 快速测试

```typescript
// 点击 "快速测试 (推荐)" 按钮
// 自动测试 Google DNS、Cloudflare DNS、Google
// 显示成功数量和总耗时
```

#### 自定义测试

```typescript
// 1. 在输入框输入地址
// 2. 点击 "测试此地址"
// 3. 查看结果消息
```

#### 高级测试

```typescript
// 批量测试: 顺序测试多个地址
// 并发测试: 同时测试多个地址
```

---

## 测试步骤

### 步骤 1: 运行应用

```bash
# 在 Xcode 中打开项目
open ios/App/App.xcworkspace

# 或使用命令行
xcodebuild -workspace ios/App/App.xcworkspace \
           -scheme App \
           -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### 步骤 2: 打开 Console

```
Command + Shift + Y (打开 Debug Area)
搜索: 🏓
```

### 步骤 3: 执行测试

#### 测试 1: 快速测试

1. 打开应用
2. 滚动到"网络延迟测试"区域
3. 点击"快速测试 (推荐)"按钮
4. 等待结果（约 9 秒）
5. 查看成功消息和 Console 日志

**预期结果：**
```
✅ Google DNS (8.8.8.8): 25 ms
✅ Cloudflare DNS (1.1.1.1): 15 ms
✅ Google (google.com): 30 ms
测试完成！3/3 个服务器可达 (9123ms)
```

#### 测试 2: 自定义地址

1. 在输入框输入 `8.8.8.8`
2. 点击"测试此地址"
3. 查看结果消息

**预期结果：**
```
✅ 8.8.8.8: 25 ms (总耗时: 9045ms)
```

#### 测试 3: 批量测试

1. 点击"批量测试"按钮
2. 等待所有测试完成
3. 查看 Console 日志

**预期结果：**
```
✅ 8.8.8.8: 25 ms
✅ 1.1.1.1: 15 ms
✅ google.com: 30 ms
✅ cloudflare.com: 18 ms
批量测试完成: 4/4 成功 (36123ms)
```

#### 测试 4: 并发测试

1. 点击"并发测试"按钮
2. 等待结果（约 9 秒）
3. 查看排序后的结果

**预期结果：**
```
✅ 1.1.1.1: 15 ms
✅ cloudflare.com: 18 ms
✅ 8.8.8.8: 25 ms
✅ google.com: 30 ms
✅ github.com: 35 ms
并发测试完成: 5/5 成功 (9234ms)
```

### 步骤 4: 验证日志

在 Xcode Console 中应该看到：

```
🏓 PingPlugin: Received ping request for: 8.8.8.8
🏓 PingPlugin: Extracted host: 8.8.8.8
🏓 PingPlugin: SwiftyPing created for 8.8.8.8
🏓 PingPlugin: Starting ping to 8.8.8.8
🏓 PingPlugin: Received response, duration: 25.34 ms
🏓 PingPlugin: Received response, duration: 26.12 ms
🏓 PingPlugin: Received response, duration: 24.89 ms
🏓 PingPlugin: Ping finished with result
🏓 PingPlugin: Average latency: 25 ms (from 3 responses)
```

---

## 故障排查

### 问题 1: 所有测试都超时

**症状：**
```
❌ 8.8.8.8: 超时
❌ google.com: 超时
```

**可能原因：**
1. iOS 模拟器限制
2. 网络未连接
3. 防火墙阻止 ICMP

**解决方法：**
```bash
# 1. 在真实 iOS 设备上测试
# 2. 检查网络连接
# 3. 尝试不同的网络环境
```

### 问题 2: 某些地址超时

**症状：**
```
✅ 8.8.8.8: 25 ms
❌ example.com: 超时
```

**可能原因：**
- 目标服务器不响应 ICMP

**解决方法：**
- 这是正常的，某些服务器配置为不响应 ICMP
- 使用已知响应 ICMP 的服务器测试

### 问题 3: PingBridge 未加载

**症状：**
```
❌ PingBridge 未加载
```

**解决方法：**
```javascript
// 检查 index.html 是否包含
<script src="/ping-bridge.js"></script>

// 检查加载顺序
<script src="/ping-bridge.js"></script>  // 先加载
<script type="module" src="/src/main.tsx"></script>  // 后加载
```

### 问题 4: 编译错误

**症状：**
```
Build failed in Xcode
```

**解决方法：**
```bash
# 1. 清理构建
cd ios/App
xcodebuild clean

# 2. 重新同步
cd ../..
npx cap sync ios

# 3. 重新构建
npm run build
```

---

## API 参考

### window.PingBridge.ping()

```typescript
ping(address: string): Promise<number | null>
```

**参数：**
- `address`: 目标地址（IP、域名、URL）

**返回值：**
- `number`: 平均延迟（毫秒）
- `null`: 超时或失败

**示例：**
```javascript
const latency = await window.PingBridge.ping('8.8.8.8');
```

### window.PingBridge.pingMultiple()

```typescript
pingMultiple(addresses: string[]): Promise<Array<{
    address: string;
    latency: number | null;
}>>
```

**参数：**
- `addresses`: 地址数组

**返回值：**
- 结果数组，按输入顺序

**示例：**
```javascript
const results = await window.PingBridge.pingMultiple([
    '8.8.8.8',
    'google.com'
]);
```

### window.PingBridge.pingConcurrent()

```typescript
pingConcurrent(addresses: string[]): Promise<Array<{
    address: string;
    latency: number | null;
}>>
```

**参数：**
- `addresses`: 地址数组

**返回值：**
- 结果数组，按输入顺序

**特点：**
- 并发执行，速度更快
- 推荐用于多个地址测试

**示例：**
```javascript
const results = await window.PingBridge.pingConcurrent([
    '8.8.8.8',
    '1.1.1.1',
    'google.com'
]);
```

---

## 📚 相关文档

- **SwiftyPing集成完成.md** - 详细的集成说明
- **SwiftyPing快速参考.md** - 快速参考卡片
- **SwiftyPing GitHub**: https://github.com/samiyr/SwiftyPing

---

## 🎉 总结

### 已完成

- ✅ SwiftyPing 库已集成
- ✅ 插件已更新并构建
- ✅ UI 已优化
- ✅ 测试代码已完善
- ✅ 文档已创建

### 下一步

1. 在 Xcode 中运行应用
2. 测试所有功能
3. 查看 Console 日志
4. 如果模拟器有问题，在真机上测试

**安装和集成已完成，可以开始使用了！** 🚀
