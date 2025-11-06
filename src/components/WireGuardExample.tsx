import React, { useState } from 'react';
import { useWireGuard } from '../hooks/useWireGuard';
import { Button, Input, message } from 'antd';

/**
 * WireGuard VPN示例组件
 * 展示如何使用WireGuard插件
 */
const WireGuardExample: React.FC = () => {
  const {
    status,
    isConnecting,
    isConnected,
    connect,
    disconnect,
    saveConfig,
    deleteConfig,
    listTunnels,
    error
  } = useWireGuard();

  const [config, setConfig] = useState(`[Interface]
PrivateKey = YOUR_PRIVATE_KEY
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = vpn.example.com:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25`);

  const [tunnelName, setTunnelName] = useState('MyVPN');
  const [tunnels, setTunnels] = useState<string[]>([]);

  const handleConnect = async () => {
    try {
      await connect(config, tunnelName);
      message.success('VPN连接成功');
    } catch (err: any) {
      message.error(`连接失败: ${err.message}`);
    }
  };

  const handleDisconnect = async () => {
    try {
      await disconnect();
      message.success('VPN已断开');
    } catch (err: any) {
      message.error(`断开失败: ${err.message}`);
    }
  };

  const handleSaveConfig = async () => {
    try {
      await saveConfig(config, tunnelName);
      message.success('配置已保存');
    } catch (err: any) {
      message.error(`保存失败: ${err.message}`);
    }
  };

  const handleDeleteConfig = async () => {
    try {
      await deleteConfig(tunnelName);
      message.success('配置已删除');
    } catch (err: any) {
      message.error(`删除失败: ${err.message}`);
    }
  };

  const handleListTunnels = async () => {
    try {
      const result = await listTunnels();
      setTunnels(result);
      message.info(`找到 ${result.length} 个隧道`);
    } catch (err: any) {
      message.error(`获取列表失败: ${err.message}`);
    }
  };

  const getStatusColor = () => {
    switch (status.status) {
      case 'connected':
        return 'text-green-500';
      case 'connecting':
        return 'text-yellow-500';
      case 'disconnected':
        return 'text-gray-500';
      default:
        return 'text-red-500';
    }
  };

  const formatBytes = (bytes?: number) => {
    if (!bytes) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return `${(bytes / Math.pow(k, i)).toFixed(2)} ${sizes[i]}`;
  };

  return (
    <div className="p-6 max-w-4xl mx-auto">
      <h1 className="text-2xl font-bold mb-6 text-white">WireGuard VPN</h1>

      {/* 状态显示 */}
      <div className="bg-gray-800 rounded-lg p-4 mb-6">
        <h2 className="text-lg font-semibold mb-3 text-white">连接状态</h2>
        <div className="space-y-2">
          <p className="text-white">
            状态: <span className={`font-bold ${getStatusColor()}`}>
              {status.status.toUpperCase()}
            </span>
          </p>
          {status.bytesUploaded !== undefined && (
            <p className="text-white">
              上传: {formatBytes(status.bytesUploaded)}
            </p>
          )}
          {status.bytesDownloaded !== undefined && (
            <p className="text-white">
              下载: {formatBytes(status.bytesDownloaded)}
            </p>
          )}
          {status.lastHandshake && (
            <p className="text-white">
              最后握手: {new Date(status.lastHandshake * 1000).toLocaleString()}
            </p>
          )}
        </div>
        {error && (
          <p className="text-red-500 mt-2">错误: {error}</p>
        )}
      </div>

      {/* 配置输入 */}
      <div className="bg-gray-800 rounded-lg p-4 mb-6">
        <h2 className="text-lg font-semibold mb-3 text-white">配置</h2>
        <div className="space-y-3">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1">
              隧道名称
            </label>
            <Input
              value={tunnelName}
              onChange={(e) => setTunnelName(e.target.value)}
              placeholder="输入隧道名称"
              className="w-full"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1">
              WireGuard配置
            </label>
            <Input.TextArea
              value={config}
              onChange={(e) => setConfig(e.target.value)}
              placeholder="粘贴WireGuard配置"
              rows={10}
              className="w-full font-mono text-sm"
            />
          </div>
        </div>
      </div>

      {/* 操作按钮 */}
      <div className="grid grid-cols-2 gap-3 mb-6">
        <Button
          type="primary"
          onClick={handleConnect}
          loading={isConnecting}
          disabled={isConnected || isConnecting}
          className="w-full"
          size="large"
        >
          {isConnecting ? '连接中...' : '连接'}
        </Button>
        <Button
          danger
          onClick={handleDisconnect}
          disabled={!isConnected}
          className="w-full"
          size="large"
        >
          断开
        </Button>
        <Button
          onClick={handleSaveConfig}
          className="w-full"
        >
          保存配置
        </Button>
        <Button
          onClick={handleDeleteConfig}
          className="w-full"
        >
          删除配置
        </Button>
      </div>

      {/* 隧道列表 */}
      <div className="bg-gray-800 rounded-lg p-4">
        <div className="flex justify-between items-center mb-3">
          <h2 className="text-lg font-semibold text-white">已保存的隧道</h2>
          <Button onClick={handleListTunnels} size="small">
            刷新
          </Button>
        </div>
        {tunnels.length > 0 ? (
          <ul className="space-y-2">
            {tunnels.map((tunnel, index) => (
              <li
                key={index}
                className="bg-gray-700 rounded px-3 py-2 text-white"
              >
                {tunnel}
              </li>
            ))}
          </ul>
        ) : (
          <p className="text-gray-400 text-center py-4">
            暂无保存的隧道
          </p>
        )}
      </div>
    </div>
  );
};

export default WireGuardExample;
