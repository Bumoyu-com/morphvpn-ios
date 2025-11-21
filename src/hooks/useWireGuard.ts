import { useState, useEffect, useCallback } from 'react';
import { message } from 'antd';
import WireGuard, { WireGuardStatus } from '../plugins/wireguard';

export interface UseWireGuardReturn {
  status: WireGuardStatus;
  isConnecting: boolean;
  isConnected: boolean;
  connect: (config: string, tunnelName: string) => Promise<void>;
  disconnect: () => Promise<void>;
  saveConfig: (config: string, tunnelName: string) => Promise<void>;
  deleteConfig: (tunnelName: string) => Promise<void>;
  listTunnels: () => Promise<string[]>;
  error: string | null;
}

/**
 * React Hook for WireGuard VPN management
 * 
 * @example
 * ```tsx
 * function VPNComponent() {
 *   const { status, isConnected, connect, disconnect } = useWireGuard();
 *   
 *   const handleConnect = async () => {
 *     await connect(myConfig, 'MyVPN');
 *   };
 *   
 *   return (
 *     <div>
 *       <p>Status: {status.status}</p>
 *       {isConnected ? (
 *         <button onClick={disconnect}>Disconnect</button>
 *       ) : (
 *         <button onClick={handleConnect}>Connect</button>
 *       )}
 *     </div>
 *   );
 * }
 * ```
 */
export function useWireGuard(): UseWireGuardReturn {
  const [status, setStatus] = useState<WireGuardStatus>({ status: 'disconnected' });
  const [isConnecting, setIsConnecting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // 获取当前状态
  const fetchStatus = useCallback(async () => {
    try {
      const currentStatus = await WireGuard.getStatus();
      setStatus(currentStatus);
    } catch (err: any) {
      message.error(`获取 VPN 状态失败: ${err.message || '未知错误'}`);
    }
  }, []);

  // 监听状态变化
  useEffect(() => {
    // 初始获取状态
    fetchStatus();

    // 监听状态变化事件
    const listener = WireGuard.addListener('statusChanged', (data: any) => {
      setStatus(prev => ({ ...prev, status: data.status }));
      if (data.status === 'connected' || data.status === 'disconnected') {
        setIsConnecting(false);
      }
    });

    // 定期更新状态（获取流量统计等）
    const interval = setInterval(fetchStatus, 5000);

    return () => {
      listener.remove();
      clearInterval(interval);
    };
  }, [fetchStatus]);

  // 连接VPN
  const connect = useCallback(async (config: string, tunnelName: string) => {
    setIsConnecting(true);
    setError(null);
    
    try {
      const result = await WireGuard.connect({ config, tunnelName });
      if (!result.success) {
        throw new Error(result.message || 'Failed to connect');
      }
    } catch (err: any) {
      setError(err.message || 'Connection failed');
      setIsConnecting(false);
      throw err;
    }
  }, []);

  // 断开VPN
  const disconnect = useCallback(async () => {
    setError(null);
    
    try {
      await WireGuard.disconnect();
    } catch (err: any) {
      setError(err.message || 'Disconnect failed');
      throw err;
    }
  }, []);

  // 保存配置
  const saveConfig = useCallback(async (config: string, tunnelName: string) => {
    setError(null);
    
    try {
      const result = await WireGuard.saveConfig({ config, tunnelName });
      if (!result.success) {
        throw new Error('Failed to save config');
      }
    } catch (err: any) {
      setError(err.message || 'Save config failed');
      throw err;
    }
  }, []);

  // 删除配置
  const deleteConfig = useCallback(async (tunnelName: string) => {
    setError(null);
    
    try {
      const result = await WireGuard.deleteConfig({ tunnelName });
      if (!result.success) {
        throw new Error('Failed to delete config');
      }
    } catch (err: any) {
      setError(err.message || 'Delete config failed');
      throw err;
    }
  }, []);

  // 列出所有隧道
  const listTunnels = useCallback(async (): Promise<string[]> => {
    try {
      const result = await WireGuard.listTunnels();
      return result.tunnels;
    } catch (err: any) {
      setError(err.message || 'List tunnels failed');
      throw err;
    }
  }, []);

  const isConnected = status.status === 'connected';

  return {
    status,
    isConnecting,
    isConnected,
    connect,
    disconnect,
    saveConfig,
    deleteConfig,
    listTunnels,
    error,
  };
}
