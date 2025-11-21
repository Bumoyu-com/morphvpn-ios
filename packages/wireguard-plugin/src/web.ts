import { WebPlugin } from '@capacitor/core';

import type { WireGuardPlugin, WireGuardStatus } from './definitions';

export class WireGuardWeb extends WebPlugin implements WireGuardPlugin {
  async connect(options: { config: string; tunnelName: string }): Promise<{ success: boolean; message?: string }> {
    console.log('WireGuard connect called on web', options);
    return { success: false, message: 'WireGuard 不支持 Web 平台，请在 iOS 设备上测试' };
  }

  async disconnect(): Promise<{ success: boolean }> {
    console.log('WireGuard disconnect called on web');
    return { success: false };
  }

  async getStatus(): Promise<WireGuardStatus> {
    return { status: 'disconnected' };
  }

  async saveConfig(options: { config: string; tunnelName: string }): Promise<{ success: boolean }> {
    console.log('WireGuard saveConfig called on web', options);
    return { success: false };
  }

  async deleteConfig(options: { tunnelName: string }): Promise<{ success: boolean }> {
    console.log('WireGuard deleteConfig called on web', options);
    return { success: false };
  }

  async listTunnels(): Promise<{ tunnels: string[] }> {
    return { tunnels: [] };
  }
}
