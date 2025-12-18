# MorphProtocol 独立插件实施指南

## 执行摘要

已成功创建 MorphProtocol 独立插件，现在需要完成以下步骤：

1. ✅ 创建独立插件结构
2. ✅ 实现插件代码
3. ⏳ 恢复 WireGuard 插件到纯净状态
4. ⏳ 创建 React 测试组件
5. ⏳ 配置和测试

---

## 已完成的工作 ✅

### 1. 创建了独立的 MorphProtocol 插件

**位置**: `packages/morphprotocol-plugin/`

**文件结构**:
```
packages/morphprotocol-plugin/
├── package.json
├── tsconfig.json
├── rollup.config.js
├── MorphvpnCapacitorMorphprotocol.podspec
├── src/
│   ├── definitions.ts
│   ├── index.ts
│   └── web.ts
└── ios/Plugin/
    ├── MorphProtocolPlugin.swift
    ├── MorphProtocolPlugin.m
    ├── MorphUDPClient.swift
    ├── MorphEncryptor.swift
    ├── MorphObfuscator.swift
    ├── ObfuscationFunctions.swift
    ├── FunctionRegistry.swift
    └── ProtocolTemplates.swift
```

### 2. 实现了完整的功能

- ✅ 11种混淆函数
- ✅ 动态函数选择
- ✅ 3种协议模板
- ✅ UDP 连接管理
- ✅ 加密/解密
- ✅ 混淆/解混淆
- ✅ 协议封装/解封装

---

## 待完成的步骤

### 步骤 1: 安装 MorphProtocol 插件

```bash
cd /workspaces/morphvpn-ios

# 安装插件依赖
cd packages/morphprotocol-plugin
npm install

# 构建插件
npm run build

# 返回项目根目录
cd ../..

# 在主项目中安装插件
npm install ./packages/morphprotocol-plugin

# 同步到 iOS
npx cap sync ios
```

---

### 步骤 2: 恢复 WireGuard 插件到纯净状态

#### 2.1 移除 MorphProtocol 相关代码

**文件**: `packages/wireguard-plugin/src/definitions.ts`

移除以下字段：
```typescript
// 删除这些字段
useMorphProtocol?: boolean;
morphEncryptionKey?: string;
morphServerHost?: string;
morphServerPort?: number;
morphLayerCount?: number;
morphPaddingLength?: number;
morphTemplateType?: number;
```

保留纯净的 WireGuard 配置：
```typescript
export interface WireGuardConnectOptions {
  config: string;
  tunnelName: string;
}
```

#### 2.2 清理 WireGuardPlugin.swift

**文件**: `packages/wireguard-plugin/ios/Plugin/WireGuardPlugin.swift`

移除 MorphProtocol 相关代码，只保留基本的 WireGuard 功能。

#### 2.3 清理 PacketTunnelProvider

**文件**: `ios/App/WireGuardExtension/PacketTunnelProvider.swift`

移除所有 MorphProtocol 相关代码：
- 移除 `morphClient` 属性
- 移除 MorphProtocol 初始化代码
- 移除 MorphProtocol 配置读取代码

保持纯净的 WireGuard 实现。

---

### 步骤 3: 创建 React 测试组件

#### 3.1 创建 TestMorphProtocol.tsx

**文件**: `src/components/TestMorphProtocol.tsx`

```typescript
import React, { useState, useEffect } from 'react';
import { Button, message, Card, Select, Input, Space } from 'antd';
import { Capacitor } from '@capacitor/core';
import { MorphProtocol } from '@morphvpn/capacitor-morphprotocol';

const { Option } = Select;

export const TestMorphProtocol: React.FC = () => {
  const [status, setStatus] = useState<string>('disconnected');
  const [host, setHost] = useState('your-server.com');
  const [port, setPort] = useState(51821);
  const [encryptionKey, setEncryptionKey] = useState('XuNgTBIiWFXHSeunT/xPi6DEp98vjw6XBoGogtIJbE8=:4jww75fhLvms4akS');
  const [layer, setLayer] = useState(3);
  const [padding, setPadding] = useState(8);
  const [templateType, setTemplateType] = useState(1);
  const [receivedData, setReceivedData] = useState<string[]>([]);

  const platform = Capacitor.getPlatform();

  useEffect(() => {
    // 监听状态变化
    MorphProtocol.addListener('statusChanged', (data) => {
      console.log('Status changed:', data);
      setStatus(data.status);
      message.info(`状态: ${data.status}`);
    });

    // 监听接收数据
    MorphProtocol.addListener('dataReceived', (data) => {
      console.log('Data received:', data);
      const decoded = atob(data.data);
      setReceivedData(prev => [...prev, decoded]);
      message.success(`收到数据: ${decoded.substring(0, 50)}...`);
    });

    return () => {
      MorphProtocol.removeAllListeners();
    };
  }, []);

  const handleConnect = async () => {
    try {
      if (platform === 'web') {
        message.warning('MorphProtocol 不支持 Web 平台，请在 iOS 设备上测试', 3);
        return;
      }

      message.loading('正在连接 MorphProtocol...', 0);

      const result = await MorphProtocol.connect({
        host,
        port,
        encryptionKey,
        obfuscationLayer: layer,
        paddingLength: padding,
        templateType,
      });

      message.destroy();

      if (result.success) {
        message.success('连接成功！');
      } else {
        message.error(`连接失败: ${result.message}`);
      }
    } catch (error: any) {
      console.error('Connect failed:', error);
      message.destroy();
      message.error(`连接失败: ${error.message}`);
    }
  };

  const handleDisconnect = async () => {
    try {
      const result = await MorphProtocol.disconnect();
      if (result.success) {
        message.success('已断开连接');
        setStatus('disconnected');
      }
    } catch (error: any) {
      message.error(`断开失败: ${error.message}`);
    }
  };

  const handleSendTest = async () => {
    try {
      const testData = 'Hello, MorphProtocol! ' + new Date().toISOString();
      const base64Data = btoa(testData);

      const result = await MorphProtocol.send({
        data: base64Data,
      });

      if (result.success) {
        message.success('测试数据已发送');
      } else {
        message.error(`发送失败: ${result.message}`);
      }
    } catch (error: any) {
      message.error(`发送失败: ${error.message}`);
    }
  };

  return (
    <Card title="MorphProtocol 测试" style={{ margin: '20px' }}>
      <Space direction="vertical" style={{ width: '100%' }} size="large">
        {/* 配置区域 */}
        <div>
          <h3>连接配置</h3>
          <Space direction="vertical" style={{ width: '100%' }}>
            <Input
              addonBefore="服务器地址"
              value={host}
              onChange={(e) => setHost(e.target.value)}
              placeholder="your-server.com"
            />
            <Input
              addonBefore="端口"
              type="number"
              value={port}
              onChange={(e) => setPort(Number(e.target.value))}
            />
            <Input.TextArea
              rows={2}
              value={encryptionKey}
              onChange={(e) => setEncryptionKey(e.target.value)}
              placeholder="加密密钥 (base64key:base64iv)"
            />
            <Select
              style={{ width: '100%' }}
              value={layer}
              onChange={setLayer}
              placeholder="混淆层数"
            >
              <Option value={1}>1层</Option>
              <Option value={2}>2层</Option>
              <Option value={3}>3层（推荐）</Option>
              <Option value={4}>4层</Option>
            </Select>
            <Select
              style={{ width: '100%' }}
              value={padding}
              onChange={setPadding}
              placeholder="填充长度"
            >
              <Option value={4}>4字节</Option>
              <Option value={8}>8字节（推荐）</Option>
              <Option value={12}>12字节</Option>
              <Option value={16}>16字节</Option>
            </Select>
            <Select
              style={{ width: '100%' }}
              value={templateType}
              onChange={setTemplateType}
              placeholder="协议模板"
            >
              <Option value={0}>无模板</Option>
              <Option value={1}>QUIC 协议（推荐）</Option>
              <Option value={2}>KCP 协议</Option>
              <Option value={3}>游戏协议</Option>
            </Select>
          </Space>
        </div>

        {/* 状态显示 */}
        <div>
          <h3>连接状态</h3>
          <div style={{ 
            padding: '10px', 
            background: status === 'connected' ? '#f6ffed' : '#fff1f0',
            border: `1px solid ${status === 'connected' ? '#b7eb8f' : '#ffa39e'}`,
            borderRadius: '4px'
          }}>
            状态: {status}
          </div>
        </div>

        {/* 操作按钮 */}
        <Space>
          <Button 
            type="primary" 
            onClick={handleConnect}
            disabled={status === 'connected'}
          >
            连接
          </Button>
          <Button 
            onClick={handleDisconnect}
            disabled={status !== 'connected'}
          >
            断开
          </Button>
          <Button 
            onClick={handleSendTest}
            disabled={status !== 'connected'}
          >
            发送测试数据
          </Button>
        </Space>

        {/* 接收数据显示 */}
        {receivedData.length > 0 && (
          <div>
            <h3>接收到的数据</h3>
            <div style={{ 
              maxHeight: '200px', 
              overflow: 'auto',
              background: '#f5f5f5',
              padding: '10px',
              borderRadius: '4px'
            }}>
              {receivedData.map((data, index) => (
                <div key={index} style={{ marginBottom: '5px' }}>
                  [{index + 1}] {data}
                </div>
              ))}
            </div>
          </div>
        )}

        {/* 平台信息 */}
        <div style={{ fontSize: '12px', color: '#999' }}>
          当前平台: {platform}
          {platform === 'web' && ' (仅支持 iOS 平台)'}
        </div>
      </Space>
    </Card>
  );
};
```

#### 3.2 添加到主页面

**文件**: `src/pages/VpnPage.tsx`

```typescript
import { TestMorphProtocol } from '../components/TestMorphProtocol';

// 在页面中添加
<TestMorphProtocol />
```

或者创建独立的测试页面：

**文件**: `src/pages/MorphProtocolTestPage.tsx`

```typescript
import React from 'react';
import { TestMorphProtocol } from '../components/TestMorphProtocol';

export const MorphProtocolTestPage: React.FC = () => {
  return (
    <div>
      <TestMorphProtocol />
    </div>
  );
};
```

---

### 步骤 4: 更新路由（如果需要独立页面）

**文件**: `src/App.tsx`

```typescript
import { MorphProtocolTestPage } from './pages/MorphProtocolTestPage';

// 添加路由
<Route path="/morphprotocol-test" element={<MorphProtocolTestPage />} />
```

---

### 步骤 5: 构建和测试

```bash
# 1. 构建 MorphProtocol 插件
cd packages/morphprotocol-plugin
npm run build
cd ../..

# 2. 安装插件到主项目
npm install ./packages/morphprotocol-plugin

# 3. 同步到 iOS
npx cap sync ios

# 4. 在 Xcode 中打开
npx cap open ios

# 5. 在 Xcode 中:
# - Clean Build Folder (⇧⌘K)
# - Build (⌘B)
# - Run on real device (⌘R)
```

---

## 测试清单

### 编译测试
- [ ] MorphProtocol 插件编译成功
- [ ] WireGuard 插件编译成功
- [ ] iOS 项目编译成功
- [ ] 无编译错误和警告

### 功能测试
- [ ] MorphProtocol 连接成功
- [ ] 数据发送成功
- [ ] 数据接收成功
- [ ] 混淆功能工作
- [ ] 协议模板工作
- [ ] 断开连接正常

### WireGuard 测试
- [ ] WireGuard 连接成功
- [ ] VPN 功能正常
- [ ] 无 MorphProtocol 干扰

---

## 预期日志

### MorphProtocol 连接成功

```
🔵 MorphProtocolPlugin: connect() called
🔵 MorphProtocolPlugin: Connecting to server.com:51821
🔵 MorphProtocolPlugin: Layer=3, Padding=8, Template=1
🔒 MorphUDPClient: Initializing...
🎭 MorphUDPClient: Using QUIC template
✅ MorphUDPClient: Initialized
🔌 MorphUDPClient: Connecting to server.com:51821
🔌 MorphUDPClient: State changed to preparing
🔌 MorphUDPClient: State changed to ready
✅ MorphUDPClient: Connection ready
```

### 数据发送

```
🔐 MorphUDPClient: Encrypted 50 → 66 bytes
🎭 MorphUDPClient: Obfuscated 66 → 75 bytes
📦 MorphUDPClient: Encapsulated with QUIC: 75 → 88 bytes
✅ MorphUDPClient: Sent 88 bytes
```

### 数据接收

```
📥 MorphUDPClient: Received 88 bytes
📦 MorphUDPClient: Decapsulated with QUIC: 88 → 75 bytes
🎭 MorphUDPClient: Deobfuscated 75 → 66 bytes
🔐 MorphUDPClient: Decrypted 66 → 50 bytes
```

---

## 故障排除

### 问题 1: 插件未找到

**症状**: `Plugin MorphProtocol does not have a web implementation`

**解决**:
1. 确认插件已安装: `npm list @morphvpn/capacitor-morphprotocol`
2. 重新同步: `npx cap sync ios`
3. 清理并重新构建

### 问题 2: 编译错误

**症状**: Swift 编译错误

**解决**:
1. 确认所有 Swift 文件已添加到 Xcode 项目
2. 检查 Target Membership
3. Clean Build Folder

### 问题 3: 连接失败

**症状**: 连接超时或失败

**解决**:
1. 检查服务器地址和端口
2. 确认加密密钥格式正确
3. 查看 Console.app 日志

---

## 文件清单

### 新创建的文件

```
packages/morphprotocol-plugin/
├── package.json
├── tsconfig.json
├── rollup.config.js
├── MorphvpnCapacitorMorphprotocol.podspec
├── src/
│   ├── definitions.ts
│   ├── index.ts
│   └── web.ts
└── ios/Plugin/
    ├── MorphProtocolPlugin.swift
    ├── MorphProtocolPlugin.m
    ├── MorphUDPClient.swift
    ├── MorphEncryptor.swift
    ├── MorphObfuscator.swift
    ├── ObfuscationFunctions.swift
    ├── FunctionRegistry.swift
    └── ProtocolTemplates.swift

src/components/
└── TestMorphProtocol.tsx

src/pages/
└── MorphProtocolTestPage.tsx (可选)
```

### 需要修改的文件

```
packages/wireguard-plugin/src/definitions.ts
packages/wireguard-plugin/ios/Plugin/WireGuardPlugin.swift
ios/App/WireGuardExtension/PacketTunnelProvider.swift
src/pages/VpnPage.tsx (或 App.tsx)
```

---

## 总结

### 已完成 ✅

1. 创建了独立的 MorphProtocol 插件
2. 实现了完整的功能
3. 包含所有混淆函数和协议模板

### 待完成 ⏳

1. 安装和配置插件
2. 恢复 WireGuard 到纯净状态
3. 创建 React 测试组件
4. 测试验证

### 预计时间

- 安装配置: 0.5 小时
- 清理 WireGuard: 0.5 小时
- 创建测试组件: 1 小时
- 测试验证: 1 小时
- **总计**: 3 小时

---

**文档版本**: 1.0  
**创建时间**: 2025-12-18  
**状态**: 待完成
