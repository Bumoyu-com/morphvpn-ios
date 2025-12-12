# MorphProtocol 集成分析报告

## 📋 项目概述

### MorphProtocol 是什么？
- **功能**：网络流量混淆系统，用于 VPN 隧道
- **目的**：绕过审查，混淆 VPN 流量
- **技术**：UDP 隧道 + 多层混淆 + 加密

### 当前状态
- ✅ 已有 Android 和 iOS 的 Capacitor 插件
- ✅ 完整的 TypeScript 服务端实现
- ✅ 包含 Demo 应用

## 🔍 命名冲突检查

### 检查结果：⚠️ 有潜在冲突

#### 1. 包名冲突
**MorphProtocol 项目**：
- 包名：`@morphprotocol/capacitor-plugin`
- 插件类：`MorphProtocolPlugin`

**你的项目**：
- 包名：`@morphvpn/capacitor-wireguard`
- 使用：`window.morphVpn`
- Bundle ID：`com.morphvpn.app`

**冲突点**：
- ❌ `morph` 前缀相同
- ❌ 全局变量可能冲突
- ✅ 包名不同（protocol vs vpn）

#### 2. 依赖冲突
**MorphProtocol 依赖**：
```json
{
  "axios": "^1.7.7",
  "dotenv": "^16.4.5",
  "ws": "^8.13.0"
}
```

**你的项目依赖**：
```json
{
  "axios": "^1.4.0",  // ⚠️ 版本不同
  // 其他依赖...
}
```

**冲突点**：
- ⚠️ axios 版本不同（1.4.0 vs 1.7.7）
- ✅ 其他依赖不冲突

## 📊 集成方案

### 方案 1：作为独立插件（推荐）

**优点**：
- ✅ 不影响现有 WireGuard 功能
- ✅ 可以独立开关
- ✅ 易于维护

**缺点**：
- ⚠️ 需要管理两个插件
- ⚠️ 增加包大小

**实施步骤**：
1. 重命名避免冲突
2. 安装为独立插件
3. 在代码中选择性使用

### 方案 2：集成到 WireGuard 插件

**优点**：
- ✅ 统一管理
- ✅ 用户体验更好

**缺点**：
- ❌ 修改复杂
- ❌ 维护困难
- ❌ 可能影响现有功能

## ✅ 推荐方案：方案 1（独立插件）

### 步骤 1：重命名避免冲突

**修改包名**：
```
@morphprotocol/capacitor-plugin
↓
@morphvpn/capacitor-morphprotocol
```

**修改全局变量**：
```typescript
// 原来
window.morphVpn

// MorphProtocol 使用
window.morphProtocol
```

### 步骤 2：创建插件目录

```bash
mkdir -p packages/morphprotocol-plugin
cd packages/morphprotocol-plugin
```

### 步骤 3：复制并修改代码

从 GitHub 下载：
```bash
git clone https://github.com/StarnesG/morphProtocol.git temp
cp -r temp/android/plugin/* packages/morphprotocol-plugin/
rm -rf temp
```

### 步骤 4：修改 package.json

```json
{
  "name": "@morphvpn/capacitor-morphprotocol",
  "version": "1.0.0",
  "description": "MorphProtocol plugin for MorphVPN",
  "main": "dist/plugin.cjs.js",
  "module": "dist/esm/index.js",
  "types": "dist/esm/index.d.ts"
}
```

### 步骤 5：解决依赖冲突

**升级 axios**：
```bash
npm install axios@^1.7.7
```

或者在 MorphProtocol 插件中锁定版本：
```json
{
  "dependencies": {
    "axios": "1.4.0"
  }
}
```

### 步骤 6：修改 iOS 实现

**创建新的插件类**：
```swift
// MorphProtocolPlugin.swift
@objc(MorphProtocolPlugin)
public class MorphProtocolPlugin: CAPPlugin {
    // 实现...
}
```

**Bundle ID**：
```
com.morphvpn.app.MorphProtocolExtension
```

### 步骤 7：在项目中使用

```typescript
// 导入两个插件
import { WireGuard } from '@morphvpn/capacitor-wireguard';
import { MorphProtocol } from '@morphvpn/capacitor-morphprotocol';

// 使用 WireGuard
await WireGuard.connect(config);

// 使用 MorphProtocol（混淆）
await MorphProtocol.connect({
  remoteAddress: 'server.com',
  remotePort: 12301,
  userId: 'user123',
  encryptionKey: 'key'
});
```

## ⚠️ 注意事项

### 1. iOS 限制
- ❌ iOS 只允许一个 VPN 连接
- ⚠️ WireGuard 和 MorphProtocol 不能同时运行
- ✅ 需要选择使用哪个

### 2. 架构建议

**选项 A：互斥使用**
```typescript
if (useMorphProtocol) {
  await MorphProtocol.connect(config);
} else {
  await WireGuard.connect(config);
}
```

**选项 B：MorphProtocol 包装 WireGuard**
```
用户 → MorphProtocol → WireGuard → 服务器
      (混淆层)      (VPN层)
```

### 3. 服务器要求
- ✅ 需要运行 MorphProtocol 服务端
- ✅ 服务端需要支持混淆协议
- ⚠️ 增加服务器复杂度

## 📝 完整集成清单

### 准备工作
- [ ] 决定使用方案（推荐方案 1）
- [ ] 检查服务器是否支持 MorphProtocol
- [ ] 备份当前项目

### 代码修改
- [ ] 创建 packages/morphprotocol-plugin 目录
- [ ] 复制 MorphProtocol 代码
- [ ] 修改包名避免冲突
- [ ] 修改 Bundle ID
- [ ] 解决依赖冲突

### iOS 配置
- [ ] 创建 MorphProtocolExtension target
- [ ] 配置 Capabilities
- [ ] 配置 Entitlements
- [ ] 添加到 Scheme

### 测试
- [ ] 单独测试 WireGuard
- [ ] 单独测试 MorphProtocol
- [ ] 测试切换功能
- [ ] 测试错误处理

## 🎯 最终建议

### 短期方案
**暂时不集成 MorphProtocol**

原因：
1. 当前 WireGuard 还有崩溃问题未解决
2. MorphProtocol 增加复杂度
3. iOS 限制一个 VPN 连接

建议：
1. 先修复 WireGuard 的 libwg-go.a 链接问题
2. 确保 WireGuard 稳定运行
3. 再考虑添加 MorphProtocol

### 长期方案
**作为高级功能添加**

实施：
1. WireGuard 作为基础 VPN
2. MorphProtocol 作为"隐身模式"
3. 用户可选择是否启用混淆

## 📞 需要帮助？

如果决定集成，我可以帮你：
1. 创建详细的集成步骤
2. 修改代码避免冲突
3. 配置 iOS 项目
4. 测试和调试

**建议先解决当前的 WireGuard 崩溃问题！**
