# WireGuard Capacitor Plugin

一个用于iOS的Capacitor WireGuard VPN插件，使用Apple的NetworkExtension框架实现。

## 功能特性

- ✅ 连接/断开WireGuard VPN
- ✅ 保存和管理多个VPN配置
- ✅ 实时状态监控
- ✅ 流量统计（上传/下载字节数）
- ✅ TypeScript类型支持
- ✅ React Hook集成
- ✅ 完整的错误处理

## 项目结构

```
morphvpn-ios/
├── src/
│   ├── plugins/
│   │   ├── wireguard.ts          # 插件接口定义
│   │   └── wireguard.web.ts      # Web平台实现（占位）
│   ├── hooks/
│   │   └── useWireGuard.ts       # React Hook
│   └── components/
│       └── WireGuardExample.tsx  # 示例组件
├── ios/
│   ├── App/
│   │   └── App/
│   │       └── Plugins/
│   │           ├── WireGuardPlugin.swift  # iOS原生实现
│   │           └── WireGuardPlugin.m      # Objective-C桥接
│   └── WIREGUARD_SETUP.md        # 详细设置指南
└── WIREGUARD_PLUGIN_README.md    # 本文件
```

## 快速开始

### 1. 安装依赖

```bash
npm install
```

### 2. 配置iOS项目

⚠️ **重要**: WireGuard需要额外的iOS配置。请仔细阅读 `ios/WIREGUARD_SETUP.md` 完成以下步骤:

1. 创建Network Extension Target
2. 添加WireGuardKit依赖
3. 配置App Capabilities (Network Extensions, Personal VPN, App Groups)
4. 创建PacketTunnelProvider
5. 配置Provisioning Profiles

### 3. 在代码中使用

#### 基础用法

```typescript
import WireGuard from './plugins/wireguard';

// WireGuard配置
const config = `
[Interface]
PrivateKey = YOUR_PRIVATE_KEY
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = vpn.example.com:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
`;

// 连接VPN
async function connect() {
  try {
    const result = await WireGuard.connect({
      config: config,
      tunnelName: 'MyVPN'
    });
    console.log('Connected:', result);
  } catch (error) {
    console.error('Failed to connect:', error);
  }
}

// 断开VPN
async function disconnect() {
  await WireGuard.disconnect();
}

// 获取状态
async function getStatus() {
  const status = await WireGuard.getStatus();
  console.log('Status:', status.status);
  console.log('Uploaded:', status.bytesUploaded);
  console.log('Downloaded:', status.bytesDownloaded);
}
```

#### 使用React Hook

```tsx
import { useWireGuard } from './hooks/useWireGuard';

function VPNComponent() {
  const {
    status,
    isConnecting,
    isConnected,
    connect,
    disconnect,
    error
  } = useWireGuard();

  const handleConnect = async () => {
    try {
      await connect(myConfig, 'MyVPN');
    } catch (err) {
      console.error('Connection failed:', err);
    }
  };

  return (
    <div>
      <p>Status: {status.status}</p>
      {status.bytesUploaded && (
        <p>Uploaded: {status.bytesUploaded} bytes</p>
      )}
      {status.bytesDownloaded && (
        <p>Downloaded: {status.bytesDownloaded} bytes</p>
      )}
      
      {error && <p className="error">{error}</p>}
      
      {isConnected ? (
        <button onClick={disconnect}>Disconnect</button>
      ) : (
        <button onClick={handleConnect} disabled={isConnecting}>
          {isConnecting ? 'Connecting...' : 'Connect'}
        </button>
      )}
    </div>
  );
}
```

#### 监听状态变化

```typescript
import WireGuard from './plugins/wireguard';

// 添加监听器
const listener = WireGuard.addListener('statusChanged', (data) => {
  console.log('VPN status changed:', data.status);
});

// 移除监听器
listener.remove();
```

## API参考

### WireGuard.connect(options)

连接到WireGuard VPN。

**参数:**
- `options.config` (string): WireGuard配置内容
- `options.tunnelName` (string): 隧道名称

**返回:** `Promise<{ success: boolean; message?: string }>`

### WireGuard.disconnect()

断开VPN连接。

**返回:** `Promise<{ success: boolean }>`

### WireGuard.getStatus()

获取当前VPN状态。

**返回:** `Promise<WireGuardStatus>`

```typescript
interface WireGuardStatus {
  status: 'disconnected' | 'connecting' | 'connected' | 'disconnecting';
  bytesUploaded?: number;
  bytesDownloaded?: number;
  lastHandshake?: number;
}
```

### WireGuard.saveConfig(options)

保存VPN配置（不连接）。

**参数:**
- `options.config` (string): WireGuard配置内容
- `options.tunnelName` (string): 隧道名称

**返回:** `Promise<{ success: boolean }>`

### WireGuard.deleteConfig(options)

删除已保存的VPN配置。

**参数:**
- `options.tunnelName` (string): 要删除的隧道名称

**返回:** `Promise<{ success: boolean }>`

### WireGuard.listTunnels()

获取所有已保存的隧道名称。

**返回:** `Promise<{ tunnels: string[] }>`

### 事件监听

#### statusChanged

当VPN状态改变时触发。

```typescript
WireGuard.addListener('statusChanged', (data: { status: string }) => {
  console.log('Status:', data.status);
});
```

## WireGuard配置格式

WireGuard配置使用INI格式:

```ini
[Interface]
PrivateKey = <客户端私钥>
Address = <客户端IP地址/子网掩码>
DNS = <DNS服务器>

[Peer]
PublicKey = <服务器公钥>
Endpoint = <服务器地址:端口>
AllowedIPs = <允许的IP范围>
PersistentKeepalive = <保持连接间隔(秒)>
```

### 配置示例

```ini
[Interface]
PrivateKey = cGFzc3dvcmQxMjM0NTY3ODkwMTIzNDU2Nzg5MDEyMzQ=
Address = 10.0.0.2/24
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = c2VydmVyX3B1YmxpY19rZXlfaGVyZQ==
Endpoint = vpn.example.com:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
```

## 测试

### 在真机上测试

⚠️ **Network Extension只能在真机上运行，不支持模拟器。**

1. 连接iOS设备到Mac
2. 在Xcode中选择你的设备
3. 点击Run
4. 首次运行时，系统会请求VPN权限

### 测试清单

- [ ] 成功连接到VPN服务器
- [ ] 能够断开连接
- [ ] 状态正确更新
- [ ] 流量统计正常显示
- [ ] 配置保存和删除功能正常
- [ ] 应用重启后配置保持
- [ ] 错误处理正确

## 故障排除

### 常见问题

#### 1. "VPN configuration is not allowed"

**原因:** 缺少必要的权限或在模拟器上运行

**解决方案:**
- 确保在真机上测试
- 检查Provisioning Profile配置
- 确认启用了Network Extensions和Personal VPN权限

#### 2. "Failed to start VPN"

**原因:** 配置错误或Network Extension未正确设置

**解决方案:**
- 验证WireGuard配置格式
- 检查Network Extension的Bundle ID是否正确
- 查看Xcode控制台的详细错误信息

#### 3. 无法连接到服务器

**原因:** 网络问题或服务器配置错误

**解决方案:**
- 检查服务器地址和端口
- 验证密钥是否正确
- 确认服务器防火墙设置

#### 4. 应用崩溃

**原因:** WireGuardKit未正确集成

**解决方案:**
- 确认WireGuardKit已添加到Network Extension target
- 检查PacketTunnelProvider实现
- 查看崩溃日志

### 调试技巧

1. **查看系统日志:**
   ```bash
   # 在Mac上查看设备日志
   xcrun simctl spawn booted log stream --predicate 'process == "WireGuardExtension"'
   ```

2. **检查VPN配置:**
   ```bash
   # 在设备上: 设置 → VPN → 查看配置
   ```

3. **使用Xcode调试器:**
   - 设置断点在`PacketTunnelProvider`
   - 查看Network Extension的控制台输出

## 安全最佳实践

1. **密钥管理:**
   - 不要在代码中硬编码私钥
   - 使用iOS Keychain存储敏感信息
   - 实施密钥轮换策略

2. **配置验证:**
   - 验证配置来源的可信度
   - 检查配置格式的有效性
   - 使用HTTPS传输配置

3. **权限控制:**
   - 仅在必要时请求VPN权限
   - 向用户解释权限用途
   - 提供清晰的隐私政策

4. **错误处理:**
   - 不要在错误消息中暴露敏感信息
   - 记录错误但不记录密钥
   - 提供用户友好的错误提示

## 性能优化

1. **连接优化:**
   - 使用合适的MTU值
   - 配置PersistentKeepalive
   - 选择最近的服务器

2. **电池优化:**
   - 避免频繁的状态查询
   - 使用事件监听而非轮询
   - 在后台时降低更新频率

3. **内存管理:**
   - 及时释放不用的资源
   - 避免内存泄漏
   - 监控Network Extension的内存使用

## 限制和注意事项

1. **平台限制:**
   - 仅支持iOS（需要iOS 12+）
   - 不支持模拟器
   - 需要付费的Apple Developer账号

2. **功能限制:**
   - 同时只能有一个VPN连接
   - 某些网络可能阻止VPN流量
   - 需要用户授权VPN权限

3. **开发限制:**
   - Network Extension调试较困难
   - 需要真机测试
   - 配置过程较复杂

## 相关资源

- [WireGuard官方网站](https://www.wireguard.com/)
- [WireGuard协议规范](https://www.wireguard.com/protocol/)
- [Apple NetworkExtension文档](https://developer.apple.com/documentation/networkextension)
- [WireGuardKit GitHub](https://github.com/passepartoutvpn/wireguard-apple)
- [Capacitor插件开发指南](https://capacitorjs.com/docs/plugins)

## 许可证

本插件遵循项目的许可证。WireGuard是Jason A. Donenfeld的注册商标。

## 贡献

欢迎提交Issue和Pull Request！

## 支持

如有问题，请查看:
1. `ios/WIREGUARD_SETUP.md` - 详细设置指南
2. 本文档的故障排除部分
3. 提交Issue到项目仓库
