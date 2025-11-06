import { registerPlugin } from '@capacitor/core';

export interface WireGuardConfig {
  /**
   * WireGuard配置内容
   */
  config: string;
  
  /**
   * 隧道名称
   */
  tunnelName: string;
}

export interface WireGuardStatus {
  /**
   * 连接状态: 'disconnected' | 'connecting' | 'connected' | 'disconnecting'
   */
  status: string;
  
  /**
   * 上传字节数
   */
  bytesUploaded?: number;
  
  /**
   * 下载字节数
   */
  bytesDownloaded?: number;
  
  /**
   * 最后握手时间戳
   */
  lastHandshake?: number;
}

export interface WireGuardPlugin {
  /**
   * 连接WireGuard VPN
   * @param options WireGuard配置
   */
  connect(options: WireGuardConfig): Promise<{ success: boolean; message?: string }>;
  
  /**
   * 断开WireGuard VPN连接
   */
  disconnect(): Promise<{ success: boolean }>;
  
  /**
   * 获取当前连接状态
   */
  getStatus(): Promise<WireGuardStatus>;
  
  /**
   * 保存WireGuard配置
   * @param options WireGuard配置
   */
  saveConfig(options: WireGuardConfig): Promise<{ success: boolean }>;
  
  /**
   * 删除WireGuard配置
   * @param options 包含tunnelName的对象
   */
  deleteConfig(options: { tunnelName: string }): Promise<{ success: boolean }>;
  
  /**
   * 获取所有已保存的隧道名称
   */
  listTunnels(): Promise<{ tunnels: string[] }>;
}

const WireGuard = registerPlugin<WireGuardPlugin>('WireGuard', {
  web: () => import('./wireguard.web').then(m => new m.WireGuardWeb()),
});

export default WireGuard;
