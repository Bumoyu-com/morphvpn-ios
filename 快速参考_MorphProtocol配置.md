# MorphProtocol 配置快速参考

## 完整配置示例

```typescript
import { useWireGuard } from '../hooks/useWireGuard';
import { validateConnectOptions } from '../utils/vpnConfigValidator';

const { connect } = useWireGuard();

const connectOptions = {
  // WireGuard 基本配置
  config: `[Interface]
PrivateKey = your_private_key
Address = 10.8.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = server_public_key
Endpoint = vpn.example.com:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25`,
  
  tunnelName: 'MorphVPN',
  
  // MorphProtocol 混淆配置
  useMorphProtocol: true,
  morphEncryptionKey: 'base64key:base64iv',  // 必需
  morphServerHost: 'morph.example.com',       // 必需
  morphServerPort: 51821,                     // 必需
  morphLayerCount: 3,                         // 可选，默认 3
  morphPaddingLength: 8                       // 可选，默认 8
};

// 验证并连接
const validation = validateConnectOptions(connectOptions);
if (validation.valid) {
  await connect(connectOptions);
} else {
  console.error(validation.error);
}
```

---

## 参数说明

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| `config` | string | ✅ | - | WireGuard 配置字符串 |
| `tunnelName` | string | ✅ | - | VPN 隧道名称 |
| `useMorphProtocol` | boolean | ❌ | false | 是否启用流量混淆 |
| `morphEncryptionKey` | string | ⚠️ | - | 加密密钥（格式：key:iv） |
| `morphServerHost` | string | ⚠️ | - | MorphProtocol 服务器地址 |
| `morphServerPort` | number | ⚠️ | - | MorphProtocol 服务器端口 |
| `morphLayerCount` | number | ❌ | 3 | 混淆层数（1-4） |
| `morphPaddingLength` | number | ❌ | 8 | 填充长度（1-16字节） |

⚠️ = 当 `useMorphProtocol: true` 时必需

---

## 生成加密密钥

```bash
# 在终端运行
node -e "const crypto = require('crypto'); \
  const key = crypto.randomBytes(32).toString('base64'); \
  const iv = crypto.randomBytes(12).toString('base64'); \
  console.log(key + ':' + iv);"
```

输出示例：
```
XuNgTBIiWFXHSeunT/xPi6DEp98vjw6XBoGogtIJbE8=:4jww75fhLvms4akS
```

---

## 性能配置建议

### 最快速度（最小混淆）
```typescript
{
  useMorphProtocol: true,
  morphLayerCount: 1,      // 最少层数
  morphPaddingLength: 1    // 最少填充
}
```

### 最强混淆（最难检测）
```typescript
{
  useMorphProtocol: true,
  morphLayerCount: 4,      // 最多层数
  morphPaddingLength: 16   // 最多填充
}
```

### 平衡配置（推荐）
```typescript
{
  useMorphProtocol: true,
  morphLayerCount: 3,      // 平衡
  morphPaddingLength: 8    // 平衡
}
```

---

## 常见错误

### ❌ 加密密钥格式错误
```
错误：MorphProtocol 加密密钥格式错误（应为 base64key:base64iv）
原因：密钥缺少冒号分隔符
解决：使用上面的命令生成正确格式的密钥
```

### ❌ 端口号无效
```
错误：MorphProtocol 服务器端口无效（应为 1-65535）
原因：端口号超出有效范围
解决：使用 1-65535 之间的端口号
```

### ❌ 混淆层数无效
```
错误：MorphProtocol 混淆层数无效（应为 1-4）
原因：层数超出支持范围
解决：使用 1-4 之间的值
```

---

## 调试技巧

### 1. 查看配置摘要
```typescript
import { getConfigSummary } from '../utils/vpnConfigValidator';

const summary = getConfigSummary(connectOptions);
console.log(summary);
```

输出：
```
隧道名称: MorphVPN
配置长度: 256 字节
MorphProtocol: 已启用
  服务器: morph.example.com:51821
  混淆层数: 3
  填充长度: 8
  密钥长度: 56 字符
```

### 2. 在 iOS 设备上查看日志
1. 连接 iOS 设备到 Mac
2. 打开 Console.app
3. 选择你的设备
4. 搜索 "MorphProtocol" 或 "WireGuard"

### 3. 预期的日志输出
```
🔍 Validating configuration...
✅ Configuration validation passed
📋 Configuration summary: ...
🔵 Calling connect with full options...
🔐 useWireGuard: MorphProtocol enabled
🔐 useWireGuard: Server: morph.example.com:51821
✅ useWireGuard: Connect successful
```

---

## 环境变量配置（可选）

### `.env.development`
```env
VITE_MORPH_ENCRYPTION_KEY=your_key:your_iv
VITE_MORPH_SERVER_HOST=morph.example.com
VITE_MORPH_SERVER_PORT=51821
VITE_MORPH_LAYER_COUNT=3
VITE_MORPH_PADDING_LENGTH=8
```

### 使用环境变量
```typescript
const connectOptions = {
  config: myConfig,
  tunnelName: 'MorphVPN',
  useMorphProtocol: true,
  morphEncryptionKey: import.meta.env.VITE_MORPH_ENCRYPTION_KEY,
  morphServerHost: import.meta.env.VITE_MORPH_SERVER_HOST,
  morphServerPort: parseInt(import.meta.env.VITE_MORPH_SERVER_PORT),
  morphLayerCount: parseInt(import.meta.env.VITE_MORPH_LAYER_COUNT),
  morphPaddingLength: parseInt(import.meta.env.VITE_MORPH_PADDING_LENGTH)
};
```

---

## 测试清单

- [ ] 配置验证通过
- [ ] 在真实 iOS 设备上测试
- [ ] MorphProtocol 服务器可访问
- [ ] 加密密钥正确
- [ ] 日志输出正常
- [ ] 网络切换正常（WiFi ↔ 蜂窝）
- [ ] 断开重连正常

---

## 相关文档

- [REACT_调用修复说明.md](./REACT_调用修复说明.md) - 详细的修复说明
- [MORPHPROTOCOL_使用示例.md](./MORPHPROTOCOL_使用示例.md) - 完整的使用示例
- [MORPHPROTOCOL_测试指南.md](./MORPHPROTOCOL_测试指南.md) - 测试指南

---

## 支持

如有问题，请检查：
1. 配置验证是否通过
2. Console.app 中的日志
3. MorphProtocol 服务器状态
4. 网络连接状态
