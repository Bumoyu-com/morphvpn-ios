# React 调用修复说明

## 修复概述

已成功修复 React 中 WireGuard 插件的调用问题，并添加了完整的配置验证功能。

---

## 修改的文件

### 1. `src/hooks/useWireGuard.ts` ✅

**修改内容**：
- 修改 `connect` 函数签名，从 `(config: string, tunnelName: string)` 改为 `(options: WireGuardConnectOptions)`
- 修改 `saveConfig` 函数签名，从 `(config: string, tunnelName: string)` 改为 `(options: WireGuardConnectOptions)`
- 添加 MorphProtocol 配置的日志输出
- 更新接口定义 `UseWireGuardReturn`

**关键变化**：
```typescript
// 之前
connect: (config: string, tunnelName: string) => Promise<void>;

// 之后
connect: (options: WireGuardConnectOptions) => Promise<void>;
```

**影响**：
- 现在可以传递完整的配置对象，包括所有 MorphProtocol 参数
- 插件将正确接收混淆配置

---

### 2. `src/components/TestVpn.tsx` ✅

**修改内容**：
- 导入配置验证函数
- 在连接前添加配置验证
- 修改 `connect` 调用，传递完整的配置对象
- 添加配置摘要日志输出

**关键变化**：
```typescript
// 之前
await connect(connectOptions.config, connectOptions.tunnelName);

// 之后
// 1. 验证配置
const validationResult = validateConnectOptions(connectOptions);
if (!validationResult.valid) {
  message.error(`配置验证失败: ${validationResult.error}`);
  return;
}

// 2. 传递完整配置
await connect(connectOptions);
```

**影响**：
- MorphProtocol 参数现在会被正确传递到插件
- 无效配置会在连接前被拦截

---

### 3. `src/utils/vpnConfigValidator.ts` ✅ (新文件)

**功能**：
- 验证 WireGuard 配置格式
- 验证 MorphProtocol 配置参数
- 生成配置摘要

**提供的函数**：

#### `validateWireGuardConfig(config: string)`
验证 WireGuard 配置是否包含必需的字段：
- `[Interface]` 段
- `[Peer]` 段
- `PrivateKey`, `Address`, `PublicKey`, `Endpoint`

#### `validateMorphProtocolConfig(options: WireGuardConnectOptions)`
验证 MorphProtocol 配置：
- 加密密钥格式（`base64key:base64iv`）
- Base64 编码有效性
- 服务器地址和端口
- 混淆层数（1-4）
- 填充长度（1-16）

#### `validateConnectOptions(options: WireGuardConnectOptions)`
验证完整的连接配置（组合上述两个验证）

#### `getConfigSummary(options: WireGuardConnectOptions)`
生成配置摘要，用于日志和调试

---

## 配置验证规则

### WireGuard 配置
- ✅ 不能为空
- ✅ 必须包含 `[Interface]` 段
- ✅ 必须包含 `[Peer]` 段
- ✅ 必须包含必需字段：`PrivateKey`, `Address`, `PublicKey`, `Endpoint`

### MorphProtocol 配置（仅在启用时）
- ✅ 加密密钥格式：`base64key:base64iv`
- ✅ Key 和 IV 必须是有效的 Base64 编码
- ✅ 服务器地址不能为空
- ✅ 服务器端口：1-65535
- ✅ 混淆层数：1-4（可选，默认 3）
- ✅ 填充长度：1-16（可选，默认 8）

---

## 使用示例

### 基本使用（启用 MorphProtocol）

```typescript
import { useWireGuard } from '../hooks/useWireGuard';
import { validateConnectOptions } from '../utils/vpnConfigValidator';

function MyVPNComponent() {
  const { connect, disconnect, isConnected } = useWireGuard();

  const handleConnect = async () => {
    const options = {
      config: wireguardConfigString,
      tunnelName: 'MyVPN',
      useMorphProtocol: true,
      morphEncryptionKey: 'your_base64_key:your_base64_iv',
      morphServerHost: 'morph.example.com',
      morphServerPort: 51821,
      morphLayerCount: 3,
      morphPaddingLength: 8
    };

    // 验证配置
    const validation = validateConnectOptions(options);
    if (!validation.valid) {
      alert(validation.error);
      return;
    }

    // 连接
    await connect(options);
  };

  return (
    <button onClick={isConnected ? disconnect : handleConnect}>
      {isConnected ? 'Disconnect' : 'Connect'}
    </button>
  );
}
```

### 不使用 MorphProtocol

```typescript
const options = {
  config: wireguardConfigString,
  tunnelName: 'MyVPN',
  useMorphProtocol: false  // 或者省略此字段
};

await connect(options);
```

---

## 验证错误示例

### 1. 加密密钥格式错误
```
配置验证失败: MorphProtocol 加密密钥格式错误（应为 base64key:base64iv）
```

### 2. 端口号无效
```
配置验证失败: MorphProtocol 服务器端口无效（应为 1-65535）
```

### 3. 混淆层数超出范围
```
配置验证失败: MorphProtocol 混淆层数无效（应为 1-4）
```

### 4. WireGuard 配置缺少必需字段
```
配置验证失败: WireGuard 配置缺少必需字段: Endpoint
```

---

## 日志输出

连接时会输出详细的日志信息：

```
🔍 Validating configuration...
✅ Configuration validation passed
📋 Configuration summary:
隧道名称: MorphVPN
配置长度: 256 字节
MorphProtocol: 已启用
  服务器: morph.example.com:51821
  混淆层数: 3
  填充长度: 8
  密钥长度: 56 字符
🔵 Calling connect with full options...
🔵 useWireGuard: connect() called
🔵 useWireGuard: tunnelName: MorphVPN
🔵 useWireGuard: config length: 256
🔐 useWireGuard: MorphProtocol enabled
🔐 useWireGuard: Server: morph.example.com:51821
🔐 useWireGuard: Layers: 3
🔐 useWireGuard: Padding: 8
```

---

## 测试建议

### 1. 测试有效配置
```typescript
const validConfig = {
  config: validWireGuardConfig,
  tunnelName: 'Test',
  useMorphProtocol: true,
  morphEncryptionKey: 'dGVzdGtleXRlc3RrZXl0ZXN0a2V5dGVzdGtleQ==:dGVzdGl2dGVzdGl2',
  morphServerHost: 'test.com',
  morphServerPort: 51821,
  morphLayerCount: 3,
  morphPaddingLength: 8
};
// 应该通过验证并成功连接
```

### 2. 测试无效的加密密钥
```typescript
const invalidKeyConfig = {
  ...validConfig,
  morphEncryptionKey: 'invalid_key_without_colon'
};
// 应该显示错误：MorphProtocol 加密密钥格式错误
```

### 3. 测试无效的端口
```typescript
const invalidPortConfig = {
  ...validConfig,
  morphServerPort: 99999
};
// 应该显示错误：MorphProtocol 服务器端口无效
```

### 4. 测试标准 WireGuard（不使用混淆）
```typescript
const standardConfig = {
  config: validWireGuardConfig,
  tunnelName: 'Standard',
  useMorphProtocol: false
};
// 应该通过验证并使用标准 WireGuard 连接
```

---

## 兼容性说明

### 向后兼容
- 如果 `useMorphProtocol` 为 `false` 或未设置，验证器会跳过 MorphProtocol 参数验证
- 标准 WireGuard 连接不受影响

### 类型安全
- 所有函数都使用 TypeScript 类型定义
- IDE 会提供完整的类型提示和自动完成

---

## 下一步

### 建议的改进
1. **环境变量管理**：将 MorphProtocol 配置移到 `.env` 文件
2. **UI 增强**：添加配置表单，让用户可以自定义参数
3. **错误恢复**：添加自动重试机制
4. **性能监控**：显示连接速度和流量统计

### 部署前检查清单
- [ ] 在真实 iOS 设备上测试
- [ ] 验证 MorphProtocol 服务器可访问
- [ ] 检查加密密钥是否正确
- [ ] 测试网络切换场景（WiFi ↔ 蜂窝网络）
- [ ] 验证日志输出是否正常

---

## 故障排除

### 问题：配置验证通过但连接失败
**可能原因**：
- MorphProtocol 服务器不可达
- 加密密钥与服务器不匹配
- WireGuard 配置错误

**解决方法**：
1. 检查服务器地址和端口
2. 验证加密密钥
3. 在 Console.app 中查看详细日志

### 问题：提示"加密密钥格式错误"
**可能原因**：
- 密钥缺少冒号分隔符
- Base64 编码无效

**解决方法**：
使用以下命令生成有效密钥：
```bash
node -e "const crypto = require('crypto'); const key = crypto.randomBytes(32).toString('base64'); const iv = crypto.randomBytes(12).toString('base64'); console.log(key + ':' + iv);"
```

### 问题：TypeScript 类型错误
**可能原因**：
- `WireGuardConnectOptions` 类型未导出

**解决方法**：
确保 `packages/wireguard-plugin/src/definitions.ts` 正确导出了类型：
```typescript
export interface WireGuardConnectOptions {
  config: string;
  tunnelName: string;
  useMorphProtocol?: boolean;
  // ... 其他字段
}
```

---

## 总结

✅ **已修复的问题**：
1. React 调用时参数传递不完整
2. Hook 接口不支持 MorphProtocol 参数
3. 缺少配置验证机制

✅ **新增功能**：
1. 完整的配置验证
2. 详细的错误提示
3. 配置摘要日志

✅ **改进**：
1. 更好的类型安全
2. 更清晰的日志输出
3. 更友好的错误处理

现在 MorphProtocol 功能应该可以正常工作了！🎉
