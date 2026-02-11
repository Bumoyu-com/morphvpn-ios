/**
 * WireGuard 连接配置
 */
export interface WireGuardConnectOptions {
  /**
   * WireGuard 配置字符串
   */
  config: string;
  
  /**
   * 隧道名称
   */
  tunnelName: string;

  /**
   * MorphProtocol 配置（JSON 字符串），传给 Network Extension 进程
   * 包含 host、sessionPort、key、layer、padding、templateId、clientID、fnInitor 等
   */
  morphConfig?: string;
}

export interface WireGuardPlugin {
  /**
   * Connect to WireGuard VPN
   */
  connect(options: WireGuardConnectOptions): Promise<{ success: boolean; message?: string }>;

  /**
   * Disconnect from WireGuard VPN
   */
  disconnect(): Promise<{ success: boolean }>;

  /**
   * Get current VPN connection status
   */
  getStatus(): Promise<WireGuardStatus>;

  /**
   * Save WireGuard configuration
   */
  saveConfig(options: WireGuardConnectOptions): Promise<{ success: boolean }>;

  /**
   * Delete WireGuard configuration
   */
  deleteConfig(options: { tunnelName: string }): Promise<{ success: boolean }>;

  /**
   * List all saved tunnel configurations
   */
  listTunnels(): Promise<{ tunnels: string[] }>;
}

export interface WireGuardStatus {
  /**
   * Connection status: 'disconnected' | 'connecting' | 'connected' | 'disconnecting'
   */
  status: string;

  /**
   * Bytes uploaded
   */
  bytesUploaded?: number;

  /**
   * Bytes downloaded
   */
  bytesDownloaded?: number;

  /**
   * Last handshake timestamp
   */
  lastHandshake?: number;
}
