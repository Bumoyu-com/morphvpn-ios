# MorphProtocol 测试密钥

## 生成的测试密钥

**生成时间**: 2025-12-12

### 完整密钥（用于测试）

```
XuNgTBIiWFXHSeunT/xPi6DEp98vjw6XBoGogtIJbE8=:4jww75fhLvms4akS
```

### 密钥组成

- **密钥 (32字节/256位)**: `XuNgTBIiWFXHSeunT/xPi6DEp98vjw6XBoGogtIJbE8=`
- **IV (12字节/96位)**: `4jww75fhLvms4akS`

---

## 如何生成新密钥

### 方法 1：使用提供的脚本

```bash
node generate-morph-key.cjs
```

### 方法 2：使用命令行

```bash
node -e "const crypto = require('crypto'); const key = crypto.randomBytes(32).toString('base64'); const iv = crypto.randomBytes(12).toString('base64'); console.log(key + ':' + iv);"
```

### 方法 3：在浏览器控制台

```javascript
// 在浏览器开发者工具的控制台中运行
async function generateKey() {
  const key = btoa(String.fromCharCode(...crypto.getRandomValues(new Uint8Array(32))));
  const iv = btoa(String.fromCharCode(...crypto.getRandomValues(new Uint8Array(12))));
  console.log(`${key}:${iv}`);
}
generateKey();
```

---

## 使用示例

### TypeScript/React

```typescript
import { Plugins } from '@capacitor/core';
const { WireGuard } = Plugins;

await WireGuard.connect({
  config: wireguardConfig,
  tunnelName: 'MorphVPN',
  useMorphProtocol: true,
  morphEncryptionKey: 'XuNgTBIiWFXHSeunT/xPi6DEp98vjw6XBoGogtIJbE8=:4jww75fhLvms4akS',
  morphServerHost: 'morph.example.com',
  morphServerPort: 51821,
  morphLayerCount: 3,
  morphPaddingLength: 8
});
```

### 环境变量方式（推荐）

```typescript
// .env.local
VITE_MORPH_ENCRYPTION_KEY=XuNgTBIiWFXHSeunT/xPi6DEp98vjw6XBoGogtIJbE8=:4jww75fhLvms4akS
VITE_MORPH_SERVER_HOST=morph.example.com
VITE_MORPH_SERVER_PORT=51821

// 代码中使用
await WireGuard.connect({
  config: wireguardConfig,
  tunnelName: 'MorphVPN',
  useMorphProtocol: true,
  morphEncryptionKey: import.meta.env.VITE_MORPH_ENCRYPTION_KEY,
  morphServerHost: import.meta.env.VITE_MORPH_SERVER_HOST,
  morphServerPort: parseInt(import.meta.env.VITE_MORPH_SERVER_PORT)
});
```

---

## ⚠️ 安全警告

### 重要提示

1. **不要在生产环境使用此测试密钥**
2. **不要将密钥提交到 Git 仓库**
3. **为每个环境生成不同的密钥**
4. **定期更换密钥**
5. **使用环境变量或密钥管理服务存储密钥**

### .gitignore 配置

确保以下文件不被提交：

```gitignore
# 环境变量文件
.env
.env.local
.env.production
.env.development

# 密钥文件
*_密钥.md
*_keys.md
*.key
*.pem

# 配置文件（如果包含密钥）
config/secrets.json
config/keys.json
```

---

## 密钥管理最佳实践

### 1. 开发环境

使用 `.env.local` 文件（不提交到 Git）：

```bash
# .env.local
VITE_MORPH_ENCRYPTION_KEY=开发环境密钥
VITE_MORPH_SERVER_HOST=dev.morph.example.com
VITE_MORPH_SERVER_PORT=51821
```

### 2. 测试环境

使用 `.env.test` 文件：

```bash
# .env.test
VITE_MORPH_ENCRYPTION_KEY=测试环境密钥
VITE_MORPH_SERVER_HOST=test.morph.example.com
VITE_MORPH_SERVER_PORT=51821
```

### 3. 生产环境

使用 CI/CD 环境变量或密钥管理服务：

- **GitHub Actions**: Repository Secrets
- **GitLab CI**: CI/CD Variables
- **AWS**: Secrets Manager
- **Azure**: Key Vault
- **Google Cloud**: Secret Manager

### 4. iOS Keychain 存储（推荐）

在生产应用中，应该使用 iOS Keychain 存储密钥：

```typescript
// 伪代码示例
import { SecureStorage } from '@capacitor/secure-storage';

// 保存密钥
await SecureStorage.set({
  key: 'morphEncryptionKey',
  value: encryptionKey
});

// 读取密钥
const { value } = await SecureStorage.get({ key: 'morphEncryptionKey' });

// 使用密钥
await WireGuard.connect({
  config: wireguardConfig,
  tunnelName: 'MorphVPN',
  useMorphProtocol: true,
  morphEncryptionKey: value,
  // ...
});
```

---

## 密钥轮换策略

### 建议的轮换周期

- **开发环境**: 每月
- **测试环境**: 每周
- **生产环境**: 每季度或发生安全事件时

### 轮换步骤

1. 生成新密钥
2. 在服务器端配置新密钥（同时保留旧密钥）
3. 更新客户端应用使用新密钥
4. 验证新密钥工作正常
5. 在服务器端移除旧密钥
6. 通知所有用户更新应用

---

## 故障排除

### 密钥格式错误

**错误**: `Encryption key format invalid`

**原因**: 密钥格式不正确

**解决**: 确保密钥格式为 `base64key:base64iv`，中间用冒号分隔

### 密钥长度错误

**错误**: `Key must be 32 bytes`

**原因**: 密钥长度不是 32 字节

**解决**: 使用提供的脚本生成正确长度的密钥

### IV 长度错误

**错误**: `Nonce must be 12 bytes`

**原因**: IV 长度不是 12 字节

**解决**: 确保 IV 部分是 12 字节的 base64 编码

---

## 测试清单

使用此密钥测试时，请确认：

- [ ] 密钥格式正确（包含冒号分隔符）
- [ ] 密钥长度正确（32字节密钥 + 12字节IV）
- [ ] 服务器端使用相同的密钥
- [ ] 网络连接正常
- [ ] 防火墙允许 UDP 流量
- [ ] 端口配置正确
- [ ] 日志显示 MorphProtocol 初始化成功

---

## 相关文档

- [MORPHPROTOCOL_集成状态.md](./MORPHPROTOCOL_集成状态.md) - 集成状态报告
- [MORPHPROTOCOL_测试指南.md](./MORPHPROTOCOL_测试指南.md) - 测试指南
- [MORPHPROTOCOL_使用示例.md](./MORPHPROTOCOL_使用示例.md) - 使用示例
- [README_MORPHPROTOCOL.md](./README_MORPHPROTOCOL.md) - 项目总览

---

**最后更新**: 2025-12-12  
**密钥状态**: 仅用于测试，不可用于生产环境
