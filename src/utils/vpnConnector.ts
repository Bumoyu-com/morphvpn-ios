/**
 * VPN 连接器 - MorphProtocol + WireGuard 架构
 *
 * 新架构（解决 iOS 进程隔离问题）：
 * 1. MorphProtocol.connect() 验证参数，返回 morphConfig JSON
 * 2. WireGuard.connect() 将 morphConfig 传入 Network Extension
 * 3. Extension 内部启动 MorphProtocol 代理、完成握手、改写 WireGuard 配置
 * 4. WireGuard 和 MorphProtocol 在同一进程内通信，不需要跨进程 localhost
 */

import { MorphProtocol } from '@morphvpn/capacitor-morphprotocol';
import { WireGuard } from '@morphvpn/capacitor-wireguard';
import { Capacitor } from '@capacitor/core';

export interface VpnConnectOptions {
  // WireGuard 配置
  wgConfig: string;
  tunnelName?: string;

  // MorphProtocol 服务器配置
  morphHost: string;
  morphPort: number;
  encryptionKey: string;
  userId: string;

  // 可选参数
  obfuscationLayer?: number;
  paddingLength?: number;
  templateType?: number;
}

export interface VpnStatus {
  connected: boolean;
  morphConnected: boolean;
  wgConnected: boolean;
  error?: string;
}

class VpnConnector {
  private wgConnected = false;

  /**
   * 连接 VPN
   */
  async connect(options: VpnConnectOptions): Promise<{ success: boolean; message?: string }> {
    const platform = Capacitor.getPlatform();

    if (platform === 'web') {
      console.warn('VPN 不支持 Web 平台');
      return { success: false, message: 'VPN 不支持 Web 平台' };
    }

    try {
      console.log('[morphVpn_ios] 连接 MorphProtocol →', `${options.morphHost}:${options.morphPort}`);

      // 1. 调用 MorphProtocol.connect() 获取 morphConfig JSON
      const morphResult = await MorphProtocol.connect({
        host: options.morphHost,
        port: options.morphPort,
        encryptionKey: options.encryptionKey,
        userId: options.userId,
        obfuscationLayer: options.obfuscationLayer ?? 3,
        paddingLength: options.paddingLength ?? 8,
        templateType: options.templateType ?? 1,
      });

      if (!morphResult.success || !morphResult.morphConfig) {
        throw new Error(`MorphProtocol 配置失败: ${morphResult.message}`);
      }

      const morphConfigJSON = morphResult.morphConfig as string;
      console.log('[morphVpn_ios] MorphProtocol 配置就绪，传入 Extension');

      // 2. 将原始 WireGuard 配置 + morphConfig 一起传给 WireGuard.connect()
      //    Extension 内部会：启动 MorphProtocol 代理 → 握手 → 改写 Endpoint → 启动 WireGuard
      console.log('[morphVpn_ios] 启动 WireGuard (含 MorphProtocol)...');

      const wgResult = await WireGuard.connect({
        config: options.wgConfig,
        tunnelName: options.tunnelName ?? 'MorphVPN',
        morphConfig: morphConfigJSON,
      });

      if (!wgResult.success) {
        throw new Error(`WireGuard 连接失败: ${wgResult.message}`);
      }

      this.wgConnected = true;
      console.log('[morphVpn_ios] VPN 连接成功');

      return { success: true };

    } catch (error: any) {
      console.error('[morphVpn_ios] 连接失败:', error);
      await this.disconnect();
      return { success: false, message: error.message };
    }
  }

  /**
   * 断开 VPN
   */
  async disconnect(): Promise<{ success: boolean; message?: string }> {
    try {
      console.log('[morphVpn_ios] 断开连接...');

      if (this.wgConnected) {
        try {
          await WireGuard.disconnect();
          console.log('[morphVpn_ios] WireGuard 已断开');
        } catch (e) {
          console.warn('[morphVpn_ios] WireGuard 断开失败:', e);
        }
        this.wgConnected = false;
      }

      // MorphProtocol 的清理由 Extension 的 stopTunnel 自动处理
      try {
        await MorphProtocol.disconnect();
      } catch (e) {
        // 忽略，Extension 已处理
      }

      return { success: true };

    } catch (error: any) {
      console.error('[morphVpn_ios] 断开失败:', error);
      return { success: false, message: error.message };
    }
  }

  /**
   * 获取状态
   */
  getStatus(): VpnStatus {
    return {
      connected: this.wgConnected,
      morphConnected: this.wgConnected, // MorphProtocol 状态跟随 WireGuard
      wgConnected: this.wgConnected,
    };
  }
}

// 导出单例
export const vpnConnector = new VpnConnector();

// 兼容旧的 window.morphVpn 接口
export function initMorphVpn() {
  (window as any).morphVpn = {
    connect: async (wgConfig: string, serverStr: string, serverInfo: any) => {
      const [morphHost, morphPortStr, userId] = serverStr.split(':');
      const morphPort = parseInt(morphPortStr, 10);

      // serverInfo 可能是字符串（加密密钥本身）或对象
      let encryptionKey = '';
      if (typeof serverInfo === 'string') {
        encryptionKey = serverInfo;
      } else {
        encryptionKey = serverInfo?.encryptionKey || serverInfo?.key || serverInfo?.info || '';
      }

      if (!encryptionKey) {
        throw new Error('缺少加密密钥');
      }

      return vpnConnector.connect({
        wgConfig,
        morphHost,
        morphPort,
        encryptionKey,
        userId,
        obfuscationLayer: serverInfo?.obfuscationLayer ?? 3,
        paddingLength: serverInfo?.paddingLength ?? 8,
        templateType: serverInfo?.templateType ?? 1,
      });
    },

    disconnect: () => vpnConnector.disconnect(),

    getStatus: () => vpnConnector.getStatus(),
  };

  console.log('✅ window.morphVpn 已初始化');
}
