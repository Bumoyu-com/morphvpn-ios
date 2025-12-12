# MorphProtocol 使用示例

## React/TypeScript 组件示例

### 1. 基本使用（不使用 MorphProtocol）

```typescript
import { Plugins } from '@capacitor/core';

const { WireGuard } = Plugins;

async function connectStandardWireGuard() {
  try {
    const result = await WireGuard.connect({
      config: `[Interface]
PrivateKey = your_private_key_here
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = server_public_key_here
Endpoint = vpn.example.com:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25`,
      tunnelName: 'MorphVPN'
    });
    
    console.log('✅ 连接成功:', result);
  } catch (error) {
    console.error('❌ 连接失败:', error);
  }
}
```

### 2. 使用 MorphProtocol 混淆

```typescript
import { Plugins } from '@capacitor/core';

const { WireGuard } = Plugins;

async function connectWithMorphProtocol() {
  try {
    const result = await WireGuard.connect({
      // WireGuard 配置
      config: `[Interface]
PrivateKey = your_private_key_here
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = server_public_key_here
Endpoint = vpn.example.com:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25`,
      tunnelName: 'MorphVPN',
      
      // MorphProtocol 配置
      useMorphProtocol: true,
      morphEncryptionKey: 'dGVzdGtleXRlc3RrZXl0ZXN0a2V5dGVzdGtleQ==:dGVzdGl2dGVzdGl2',
      morphServerHost: 'morph.example.com',
      morphServerPort: 51821,
      morphLayerCount: 3,
      morphPaddingLength: 8
    });
    
    console.log('✅ 使用 MorphProtocol 连接成功:', result);
  } catch (error) {
    console.error('❌ 连接失败:', error);
  }
}
```

### 3. 完整的 React 组件示例

```typescript
import React, { useState, useEffect } from 'react';
import { Plugins } from '@capacitor/core';

const { WireGuard } = Plugins;

interface VPNConfig {
  wireguardConfig: string;
  useMorphProtocol: boolean;
  morphEncryptionKey?: string;
  morphServerHost?: string;
  morphServerPort?: number;
}

const VPNControl: React.FC = () => {
  const [status, setStatus] = useState<string>('disconnected');
  const [loading, setLoading] = useState<boolean>(false);
  const [config, setConfig] = useState<VPNConfig>({
    wireguardConfig: '',
    useMorphProtocol: false,
    morphEncryptionKey: '',
    morphServerHost: '',
    morphServerPort: 51821
  });

  // 监听状态变化
  useEffect(() => {
    const statusListener = WireGuard.addListener('statusChanged', (data: any) => {
      console.log('VPN 状态变化:', data.status);
      setStatus(data.status);
    });

    // 获取初始状态
    checkStatus();

    return () => {
      statusListener.remove();
    };
  }, []);

  const checkStatus = async () => {
    try {
      const result = await WireGuard.getStatus();
      setStatus(result.status);
    } catch (error) {
      console.error('获取状态失败:', error);
    }
  };

  const connect = async () => {
    setLoading(true);
    try {
      const options: any = {
        config: config.wireguardConfig,
        tunnelName: 'MorphVPN'
      };

      // 如果启用 MorphProtocol，添加相关配置
      if (config.useMorphProtocol) {
        options.useMorphProtocol = true;
        options.morphEncryptionKey = config.morphEncryptionKey;
        options.morphServerHost = config.morphServerHost;
        options.morphServerPort = config.morphServerPort;
        options.morphLayerCount = 3;
        options.morphPaddingLength = 8;
      }

      await WireGuard.connect(options);
      console.log('✅ 连接成功');
    } catch (error) {
      console.error('❌ 连接失败:', error);
      alert(`连接失败: ${error}`);
    } finally {
      setLoading(false);
    }
  };

  const disconnect = async () => {
    setLoading(true);
    try {
      await WireGuard.disconnect();
      console.log('✅ 断开连接成功');
    } catch (error) {
      console.error('❌ 断开连接失败:', error);
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = () => {
    switch (status) {
      case 'connected':
        return 'green';
      case 'connecting':
        return 'yellow';
      case 'disconnected':
        return 'gray';
      default:
        return 'red';
    }
  };

  return (
    <div className="vpn-control">
      <h2>VPN 控制面板</h2>
      
      {/* 状态显示 */}
      <div className="status-indicator">
        <span 
          className="status-dot" 
          style={{ backgroundColor: getStatusColor() }}
        />
        <span>状态: {status}</span>
      </div>

      {/* WireGuard 配置 */}
      <div className="config-section">
        <h3>WireGuard 配置</h3>
        <textarea
          value={config.wireguardConfig}
          onChange={(e) => setConfig({ ...config, wireguardConfig: e.target.value })}
          placeholder="粘贴 WireGuard 配置..."
          rows={10}
          disabled={status === 'connected' || status === 'connecting'}
        />
      </div>

      {/* MorphProtocol 配置 */}
      <div className="config-section">
        <h3>MorphProtocol 混淆（可选）</h3>
        
        <label>
          <input
            type="checkbox"
            checked={config.useMorphProtocol}
            onChange={(e) => setConfig({ ...config, useMorphProtocol: e.target.checked })}
            disabled={status === 'connected' || status === 'connecting'}
          />
          启用 MorphProtocol 流量混淆
        </label>

        {config.useMorphProtocol && (
          <div className="morph-config">
            <input
              type="text"
              placeholder="加密密钥 (base64key:base64iv)"
              value={config.morphEncryptionKey}
              onChange={(e) => setConfig({ ...config, morphEncryptionKey: e.target.value })}
              disabled={status === 'connected' || status === 'connecting'}
            />
            
            <input
              type="text"
              placeholder="MorphProtocol 服务器地址"
              value={config.morphServerHost}
              onChange={(e) => setConfig({ ...config, morphServerHost: e.target.value })}
              disabled={status === 'connected' || status === 'connecting'}
            />
            
            <input
              type="number"
              placeholder="端口"
              value={config.morphServerPort}
              onChange={(e) => setConfig({ ...config, morphServerPort: parseInt(e.target.value) })}
              disabled={status === 'connected' || status === 'connecting'}
            />
          </div>
        )}
      </div>

      {/* 控制按钮 */}
      <div className="control-buttons">
        {status === 'disconnected' || status === 'invalid' ? (
          <button 
            onClick={connect} 
            disabled={loading || !config.wireguardConfig}
            className="btn-connect"
          >
            {loading ? '连接中...' : '连接'}
          </button>
        ) : (
          <button 
            onClick={disconnect} 
            disabled={loading}
            className="btn-disconnect"
          >
            {loading ? '断开中...' : '断开连接'}
          </button>
        )}
      </div>

      {/* 提示信息 */}
      {config.useMorphProtocol && (
        <div className="info-box">
          <p>ℹ️ MorphProtocol 已启用，您的流量将被加密和混淆</p>
          <p>📊 混淆层数: 3 | 填充长度: 8 字节</p>
        </div>
      )}
    </div>
  );
};

export default VPNControl;
```

### 4. 配置管理示例

```typescript
import { Plugins } from '@capacitor/core';

const { WireGuard } = Plugins;

// 保存配置
async function saveVPNConfig(config: string, tunnelName: string) {
  try {
    await WireGuard.saveConfig({
      config,
      tunnelName,
      useMorphProtocol: true,
      morphEncryptionKey: 'your_key_here',
      morphServerHost: 'morph.example.com',
      morphServerPort: 51821
    });
    console.log('✅ 配置已保存');
  } catch (error) {
    console.error('❌ 保存配置失败:', error);
  }
}

// 删除配置
async function deleteVPNConfig(tunnelName: string) {
  try {
    await WireGuard.deleteConfig({ tunnelName });
    console.log('✅ 配置已删除');
  } catch (error) {
    console.error('❌ 删除配置失败:', error);
  }
}

// 列出所有配置
async function listAllConfigs() {
  try {
    const result = await WireGuard.listTunnels();
    console.log('📋 已保存的配置:', result.tunnels);
    return result.tunnels;
  } catch (error) {
    console.error('❌ 获取配置列表失败:', error);
    return [];
  }
}
```

### 5. 状态监听示例

```typescript
import { useEffect, useState } from 'react';
import { Plugins } from '@capacitor/core';

const { WireGuard } = Plugins;

function useVPNStatus() {
  const [status, setStatus] = useState<string>('disconnected');
  const [bytesUploaded, setBytesUploaded] = useState<number>(0);
  const [bytesDownloaded, setBytesDownloaded] = useState<number>(0);

  useEffect(() => {
    // 监听状态变化
    const listener = WireGuard.addListener('statusChanged', (data: any) => {
      setStatus(data.status);
    });

    // 定期获取详细状态
    const interval = setInterval(async () => {
      try {
        const result = await WireGuard.getStatus();
        setStatus(result.status);
        if (result.bytesUploaded !== undefined) {
          setBytesUploaded(result.bytesUploaded);
        }
        if (result.bytesDownloaded !== undefined) {
          setBytesDownloaded(result.bytesDownloaded);
        }
      } catch (error) {
        console.error('获取状态失败:', error);
      }
    }, 5000); // 每5秒更新一次

    return () => {
      listener.remove();
      clearInterval(interval);
    };
  }, []);

  return { status, bytesUploaded, bytesDownloaded };
}

// 使用示例
function VPNStatusDisplay() {
  const { status, bytesUploaded, bytesDownloaded } = useVPNStatus();

  const formatBytes = (bytes: number) => {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
  };

  return (
    <div>
      <p>状态: {status}</p>
      <p>上传: {formatBytes(bytesUploaded)}</p>
      <p>下载: {formatBytes(bytesDownloaded)}</p>
    </div>
  );
}
```

### 6. 错误处理示例

```typescript
import { Plugins } from '@capacitor/core';

const { WireGuard } = Plugins;

async function connectWithErrorHandling() {
  try {
    await WireGuard.connect({
      config: wireguardConfig,
      tunnelName: 'MorphVPN',
      useMorphProtocol: true,
      morphEncryptionKey: encryptionKey,
      morphServerHost: serverHost,
      morphServerPort: serverPort
    });
    
    console.log('✅ 连接成功');
    
  } catch (error: any) {
    console.error('❌ 连接失败:', error);
    
    // 根据错误类型提供不同的提示
    if (error.message?.includes('configuration')) {
      alert('配置错误，请检查 WireGuard 配置是否正确');
    } else if (error.message?.includes('MorphProtocol')) {
      alert('MorphProtocol 初始化失败，请检查加密密钥和服务器地址');
    } else if (error.message?.includes('permission')) {
      alert('需要 VPN 权限，请在系统设置中允许');
    } else {
      alert(`连接失败: ${error.message || '未知错误'}`);
    }
  }
}
```

### 7. 生成加密密钥

在使用 MorphProtocol 之前，需要生成加密密钥：

```bash
# 在终端运行
node -e "const crypto = require('crypto'); const key = crypto.randomBytes(32).toString('base64'); const iv = crypto.randomBytes(12).toString('base64'); console.log(key + ':' + iv);"
```

输出示例：
```
dGVzdGtleXRlc3RrZXl0ZXN0a2V5dGVzdGtleQ==:dGVzdGl2dGVzdGl2
```

将这个密钥保存并用于 `morphEncryptionKey` 参数。

### 8. 配置参数说明

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| `config` | string | ✅ | - | WireGuard 配置字符串 |
| `tunnelName` | string | ✅ | - | VPN 隧道名称 |
| `useMorphProtocol` | boolean | ❌ | false | 是否启用 MorphProtocol |
| `morphEncryptionKey` | string | ❌ | - | 加密密钥（格式：base64key:base64iv）|
| `morphServerHost` | string | ❌ | - | MorphProtocol 服务器地址 |
| `morphServerPort` | number | ❌ | 0 | MorphProtocol 服务器端口 |
| `morphLayerCount` | number | ❌ | 3 | 混淆层数（1-4）|
| `morphPaddingLength` | number | ❌ | 8 | 填充长度（1-16字节）|

### 9. 性能优化建议

**最佳性能配置**：
```typescript
{
  useMorphProtocol: true,
  morphLayerCount: 1,      // 更少的层 = 更快
  morphPaddingLength: 4    // 更少的填充 = 更少开销
}
```

**最大混淆配置**：
```typescript
{
  useMorphProtocol: true,
  morphLayerCount: 4,      // 更多的层 = 更难检测
  morphPaddingLength: 16   // 更多的填充 = 更少模式
}
```

**平衡配置**（推荐）：
```typescript
{
  useMorphProtocol: true,
  morphLayerCount: 3,      // 平衡性能和安全
  morphPaddingLength: 8    // 适中的填充
}
```

### 10. 调试技巧

在开发过程中，可以在 Mac 上使用 Console.app 查看日志：

1. 打开 Console.app
2. 连接 iOS 设备
3. 搜索 "MorphProtocol" 或 "WireGuard"
4. 查看详细日志输出

预期日志：
```
🔐 MorphProtocol 已启用
🔐 MorphProtocol 配置:
   服务器: morph.example.com:51821
   混淆层数: 3
   填充长度: 8
✅ MorphProtocol 启动成功
🔐 MorphProtocol 状态: ready
🔐 MorphProtocol 状态: connected
```

---

## 注意事项

1. **真实设备测试**：VPN 功能只能在真实 iOS 设备上测试，模拟器不支持
2. **权限请求**：首次连接时会请求 VPN 权限，用户需要允许
3. **服务器要求**：使用 MorphProtocol 需要部署对应的服务器端
4. **密钥安全**：不要在代码中硬编码密钥，应该从安全存储中读取
5. **错误处理**：始终添加 try-catch 处理连接错误

---

## 完整示例项目结构

```
src/
├── components/
│   ├── VPNControl.tsx          # VPN 控制组件
│   ├── VPNStatus.tsx           # 状态显示组件
│   └── ConfigManager.tsx       # 配置管理组件
├── hooks/
│   ├── useVPNStatus.ts         # VPN 状态 Hook
│   └── useVPNConnection.ts     # VPN 连接 Hook
├── services/
│   ├── vpnService.ts           # VPN 服务封装
│   └── configService.ts        # 配置服务
└── types/
    └── vpn.types.ts            # TypeScript 类型定义
```

这样的结构可以让代码更加模块化和易于维护。
