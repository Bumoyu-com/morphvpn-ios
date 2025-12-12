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
   * 是否启用 MorphProtocol 混淆（可选）
   */
  useMorphProtocol?: boolean;
  
  /**
   * MorphProtocol 加密密钥（格式：base64key:base64iv）
   */
  morphEncryptionKey?: string;
  
  /**
   * MorphProtocol 服务器地址
   */
  morphServerHost?: string;
  
  /**
   * MorphProtocol 服务器端口
   */
  morphServerPort?: number;
  
  /**
   * MorphProtocol 混淆层数（1-4，默认3）
   */
  morphLayerCount?: number;
  
  /**
   * MorphProtocol 随机填充长度（1-16字节，默认8）
   */
  morphPaddingLength?: number;
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
