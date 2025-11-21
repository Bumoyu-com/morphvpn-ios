export interface WireGuardPlugin {
  /**
   * Connect to WireGuard VPN
   */
  connect(options: { config: string; tunnelName: string }): Promise<{ success: boolean; message?: string }>;

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
  saveConfig(options: { config: string; tunnelName: string }): Promise<{ success: boolean }>;

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
