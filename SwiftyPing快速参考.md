# SwiftyPing 快速参考

## 🎯 核心改进

- ✅ 使用成熟的 SwiftyPing 库（226 stars）
- ✅ 替换不稳定的自定义 ICMP 实现
- ✅ 更好的错误处理和稳定性
- ✅ 优化的用户界面

## 📦 安装方法

### 已完成的集成

```bash
# 1. SwiftyPing.swift 已下载到插件目录
packages/ping-plugin/ios/Plugin/SwiftyPing.swift

# 2. PingPlugin.swift 已更新使用 SwiftyPing

# 3. 已构建并同步
npm run build && npx cap sync ios
```

### 文件变化

```
✅ 新增: SwiftyPing.swift (34KB)
✅ 更新: PingPlugin.swift (使用 SwiftyPing)
❌ 删除: ICMPPinger.swift (不再需要)
```

## 🚀 使用方法

### 1. JavaScript 调用（不变）

```javascript
// 单个地址
const latency = await window.PingBridge.ping('8.8.8.8');

// 批量测试
const results = await window.PingBridge.pingMultiple(['8.8.8.8', 'google.com']);

// 并发测试
const results = await window.PingBridge.pingConcurrent(['8.8.8.8', '1.1.1.1']);
```

### 2. LoginPage 测试界面

#### 快速测试（推荐）✨

```
点击 "快速测试 (推荐)" 按钮
→ 自动测试 Google DNS、Cloudflare DNS、Google
→ 显示成功数量和总耗时
```

#### 自定义测试

```
1. 输入地址（如 8.8.8.8）
2. 点击 "测试此地址"
3. 查看结果消息
```

#### 高级测试

```
批量测试: 顺序测试多个地址
并发测试: 同时测试多个地址（更快）
```

## 📊 测试示例

### 快速测试代码

```typescript
async function testQuickPing() {
    const testServers = [
        { name: 'Google DNS', address: '8.8.8.8' },
        { name: 'Cloudflare DNS', address: '1.1.1.1' },
        { name: 'Google', address: 'google.com' }
    ];
    
    const results = await window.PingBridge.pingConcurrent(
        testServers.map(s => s.address)
    );
    
    // 显示结果
    results.forEach((result, index) => {
        const server = testServers[index];
        if (result.latency !== null) {
            console.log(`✅ ${server.name}: ${result.latency} ms`);
        } else {
            console.log(`❌ ${server.name}: 超时`);
        }
    });
}
```

## 🎨 UI 布局

```
┌─────────────────────────────────┐
│  登录                            │
│  [邮箱输入框]                    │
│  [密码输入框]                    │
│  [登录按钮]                      │
├─────────────────────────────────┤
│  🏓 网络延迟测试                 │
│                                  │
│  [快速测试 (推荐)]               │  ← 一键测试
│                                  │
│  [输入地址框]                    │
│  [测试此地址]                    │
│                                  │
│  [批量测试] [并发测试]           │  ← 高级功能
└─────────────────────────────────┘
```

## 🔧 SwiftyPing 配置

### 当前配置

```swift
PingConfiguration(
    interval: 0.5,  // ping 间隔 0.5 秒
    with: 3         // 超时时间 3 秒
)

pinger.targetCount = 3  // ping 3 次
```

### 结果处理

```swift
pinger.observer = { response in
    let duration = response.duration * 1000.0  // 转换为毫秒
    latencies.append(duration)
}
```

## 📝 日志示例

### 成功

```
🏓 PingPlugin: Received ping request for: 8.8.8.8
🏓 PingPlugin: SwiftyPing created for 8.8.8.8
🏓 PingPlugin: Received response, duration: 25.34 ms
🏓 PingPlugin: Average latency: 25 ms (from 3 responses)
✅ 8.8.8.8: 25 ms
```

### 失败

```
🏓 PingPlugin: Received ping request for: invalid.host
❌ PingPlugin: Failed to create pinger: [错误]
🏓 PingPlugin: All pings failed, returning null
❌ invalid.host: 超时
```

## ⚡ 性能对比

| 测试类型 | 地址数量 | 预期耗时 |
|---------|---------|---------|
| 单个测试 | 1 | ~9秒 (3次×3秒) |
| 批量测试 | 5 | ~45秒 (顺序) |
| 并发测试 | 5 | ~9秒 (并发) |

## ⚠️ 注意事项

### iOS 模拟器

- ⚠️ 可能不支持 ICMP
- ✅ 建议在真机上测试

### 推荐测试地址

- ✅ `8.8.8.8` - Google DNS
- ✅ `1.1.1.1` - Cloudflare DNS
- ✅ `google.com` - Google
- ⚠️ 某些服务器不响应 ICMP

### 超时设置

- 单次 ping: 3 秒
- 总超时: 10 秒
- 返回值: 整数毫秒或 null

## 🎯 测试清单

### 基础测试

- [ ] 快速测试按钮
- [ ] 输入 `8.8.8.8` 测试
- [ ] 输入 `google.com` 测试
- [ ] 输入 `https://google.com` 测试

### 高级测试

- [ ] 批量测试按钮
- [ ] 并发测试按钮
- [ ] 无效地址测试
- [ ] 超时测试

### 验证项

- [ ] 成功显示延迟值
- [ ] 失败显示超时
- [ ] Console 日志正确
- [ ] UI 消息提示正确

## 🚀 快速开始

### 1. 运行应用

```bash
open ios/App/App.xcworkspace
# Command + R
```

### 2. 测试

1. 打开应用
2. 点击"快速测试 (推荐)"
3. 查看结果

### 3. 查看日志

```
Command + Shift + Y (打开 Console)
搜索: 🏓
```

## 📚 相关文件

- **插件源码**: `packages/ping-plugin/ios/Plugin/`
- **SwiftyPing**: `SwiftyPing.swift`
- **插件接口**: `PingPlugin.swift`
- **测试页面**: `src/pages/LoginPage.tsx`
- **JS Bridge**: `public/ping-bridge.js`

## 🎉 完成状态

- ✅ SwiftyPing 已集成
- ✅ 插件已更新
- ✅ UI 已优化
- ✅ 测试代码已完善
- ✅ 文档已创建
- ✅ 已构建并同步

**可以开始测试了！** 🚀
