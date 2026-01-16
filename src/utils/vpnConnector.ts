/**
 * VPN 连接器 - 使用 MorphProtocol + WireGuard 架构
 * 
 * 连接流程:
 * 1. 启动 MorphProtocol 本地代理
 * 2. 等待握手完成获取本地端口
 * 3. 修改 WireGuard 配置，将 Endpoint 改为本地代理端口
 * 4. 启动 WireGuard 连接
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
  localPort?: number;
  sessionPort?: number;
  error?: string;
}

class VpnConnector {
  private morphConnected = false;
  private wgConnected = false;
  private localPort: number | null = null;
  private sessionPort: number | null = null;
  private listeners: any[] = [];

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
      console.log('🔵 VpnConnector: 开始连接...');
      
      // 1. 启动 MorphProtocol 代理
      console.log('🔵 VpnConnector: 启动 MorphProtocol 代理...');
      
      const morphResult = await MorphProtocol.connect({
        host: options.morphHost,
        port: options.morphPort,
        encryptionKey: options.encryptionKey,
        userId: options.userId,
        obfuscationLayer: options.obfuscationLayer ?? 3,
        paddingLength: options.paddingLength ?? 8,
        templateType: options.templateType ?? 1,
      });

      if (!morphResult.success) {
        throw new Error(`MorphProtocol 连接失败: ${morphResult.message}`);
      }

      this.localPort = morphResult.localPort ?? null;
      console.log(`✅ VpnConnector: MorphProtocol 本地端口: ${this.localPort}`);

      // 2. 等待握手完成
      await this.waitForHandshake();
      console.log(`✅ VpnConnector: MorphProtocol 握手完成，会话端口: ${this.sessionPort}`);
      
      this.morphConnected = true;

      // 3. 修改 WireGuard 配置
      const modifiedConfig = this.modifyWgConfig(options.wgConfig, this.localPort!);
      console.log('🔵 VpnConnector: WireGuard 配置已修改');

      // 4. 启动 WireGuard
      console.log('🔵 VpnConnector: 启动 WireGuard...');
      
      const wgResult = await WireGuard.connect({
        config: modifiedConfig,
        tunnelName: options.tunnelName ?? 'MorphVPN',
      });

      if (!wgResult.success) {
        throw new Error(`WireGuard 连接失败: ${wgResult.message}`);
      }

      this.wgConnected = true;
      console.log('✅ VpnConnector: VPN 连接成功!');

      return { success: true };

    } catch (error: any) {
      console.error('❌ VpnConnector: 连接失败:', error);
      
      // 清理
      await this.disconnect();
      
      return { success: false, message: error.message };
    }
  }

  /**
   * 断开 VPN
   */
  async disconnect(): Promise<{ success: boolean; message?: string }> {
    try {
      console.log('🔵 VpnConnector: 断开连接...');

      // 先断开 WireGuard
      if (this.wgConnected) {
        try {
          await WireGuard.disconnect();
          console.log('✅ VpnConnector: WireGuard 已断开');
        } catch (e) {
          console.warn('⚠️ VpnConnector: WireGuard 断开失败:', e);
        }
        this.wgConnected = false;
      }

      // 再断开 MorphProtocol
      if (this.morphConnected) {
        try {
          await MorphProtocol.disconnect();
          console.log('✅ VpnConnector: MorphProtocol 已断开');
        } catch (e) {
          console.warn('⚠️ VpnConnector: MorphProtocol 断开失败:', e);
        }
        this.morphConnected = false;
      }

      // 清理监听器
      this.removeListeners();

      this.localPort = null;
      this.sessionPort = null;

      console.log('✅ VpnConnector: 已断开连接');
      return { success: true };

    } catch (error: any) {
      console.error('❌ VpnConnector: 断开失败:', error);
      return { success: false, message: error.message };
    }
  }

  /**
   * 获取状态
   */
  getStatus(): VpnStatus {
    return {
      connected: this.morphConnected && this.wgConnected,
      morphConnected: this.morphConnected,
      wgConnected: this.wgConnected,
      localPort: this.localPort ?? undefined,
      sessionPort: this.sessionPort ?? undefined,
    };
  }

  /**
   * 等待 MorphProtocol 握手完成
   */
  private waitForHandshake(): Promise<void> {
    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        reject(new Error('MorphProtocol 握手超时'));
      }, 30000); // 30秒超时

      const listener = MorphProtocol.addListener('handshakeComplete', (data: any) => {
        clearTimeout(timeout);
        this.sessionPort = data.sessionPort;
        resolve();
      });

      this.listeners.push(listener);

      // 也监听错误
      const errorListener = MorphProtocol.addListener('statusChanged', (data: any) => {
        if (data.status === 'failed') {
          clearTimeout(timeout);
          reject(new Error(data.error || 'MorphProtocol 连接失败'));
        }
      });

      this.listeners.push(errorListener);
    });
  }

  /**
   * 修改 WireGuard 配置，将 Endpoint 改为本地代理
   */
  private modifyWgConfig(config: string, localPort: number): string {
    const lines = config.split('\n');
    const modifiedLines = lines.map(line => {
      // 匹配 Endpoint = xxx:xxx 格式
      if (line.trim().toLowerCase().startsWith('endpoint')) {
        return `Endpoint = 127.0.0.1:${localPort}`;
      }
      return line;
    });
    return modifiedLines.join('\n');
  }

  /**
   * 清理监听器
   */
  private removeListeners() {
    this.listeners.forEach(listener => {
      if (listener && typeof listener.remove === 'function') {
        listener.remove();
      }
    });
    this.listeners = [];
  }
}

// 导出单例
export const vpnConnector = new VpnConnector();

// 兼容旧的 window.morphVpn 接口
export function initMorphVpn() {
  (window as any).morphVpn = {
    connect: async (wgConfig: string, serverStr: string, serverInfo: any) => {
      // 解析 serverStr: "ip:port:userId"
      const [morphHost, morphPortStr, userId] = serverStr.split(':');
      const morphPort = parseInt(morphPortStr, 10);
      
      // 从 serverInfo 获取加密密钥
      const encryptionKey = serverInfo?.encryptionKey || serverInfo?.key || '';
      
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
