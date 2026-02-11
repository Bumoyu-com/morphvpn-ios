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
   * MorphProtocol 配置 JSON 字符串（可选）。
   * 传入后，Network Extension 内部会启动 MorphProtocol 代理，
   * 自动改写 WireGuard Endpoint 和 AllowedIPs。
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
