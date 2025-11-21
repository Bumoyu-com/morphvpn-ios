import { WebPlugin } from '@capacitor/core';
import type { WireGuardPlugin, WireGuardConfig, WireGuardStatus } from './wireguard';

export class WireGuardWeb extends WebPlugin implements WireGuardPlugin {
  async connect(options: WireGuardConfig): Promise<{ success: boolean; message?: string }> {
    return { success: false, message: 'WireGuard 不支持 Web 平台，请在 iOS 设备上测试' };
  }

  async disconnect(): Promise<{ success: boolean }> {
    return { success: false };
  }

  async getStatus(): Promise<WireGuardStatus> {
    return { status: 'disconnected' };
  }

  async saveConfig(options: WireGuardConfig): Promise<{ success: boolean }> {
    return { success: false };
  }

  async deleteConfig(options: { tunnelName: string }): Promise<{ success: boolean }> {
    return { success: false };
  }

  async listTunnels(): Promise<{ tunnels: string[] }> {
    return { tunnels: [] };
  }
}
