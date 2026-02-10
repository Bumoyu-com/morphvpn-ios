/**
 * iOS 端 morphVpn 调用接口
 *
 * 对标 Android 端 morphVpn_android.js，提供统一的 window.morphVpn API。
 * 连接流程：MorphProtocol 握手 → 获取本地代理端口 → 改写 WireGuard Endpoint → 启动 WireGuard
 *
 * 调用方式（与 Android 一致）：
 *   window.morphVpn.connect(wgConfigText, "ip:port:userId", { encryptionKey, ... })
 *   window.morphVpn.disconnect()
 *   window.morphVpn.getStatus()
 */

import { Capacitor } from '@capacitor/core';
import { MorphProtocol } from '@morphvpn/capacitor-morphprotocol';
import { WireGuard } from '@morphvpn/capacitor-wireguard';

// ---------- WireGuard 配置解析/序列化 ----------

interface WgConfigObj {
  [section: string]: { [key: string]: string | string[] };
}

function wgConfigToObj(input: string): WgConfigObj {
  const lines = input.split('\n');
  const result: WgConfigObj = {};
  let currentSection: string | null = null;

  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      currentSection = trimmed.slice(1, -1);
      result[currentSection] = {};
    } else if (currentSection && trimmed.includes(' = ')) {
      const eqIndex = trimmed.indexOf(' = ');
      const key = trimmed.substring(0, eqIndex).trim();
      const value = trimmed.substring(eqIndex + 3).trim();
      if (key === 'DNS' || key === 'AllowedIPs') {
        result[currentSection][key] = value.split(',').map((s) => s.trim());
      } else {
        result[currentSection][key] = value;
      }
    }
  }
  return result;
}

function objToWgConfig(config: WgConfigObj, endPort: number): string {
  const iface = config['Interface'] || {};
  const peer = config['Peer'] || {};
  const dns = Array.isArray(iface.DNS) ? iface.DNS.join(',') : iface.DNS || '';
  const allowedIPs = Array.isArray(peer.AllowedIPs)
    ? peer.AllowedIPs.join(',')
    : peer.AllowedIPs || '0.0.0.0/0';

  return `[Interface]
Address = ${iface.Address || ''}
DNS = ${dns}
PrivateKey = ${iface.PrivateKey || ''}
ListenPort = 51820

[Peer]
AllowedIPs = ${allowedIPs}
Endpoint = 127.0.0.1:${endPort}
PresharedKey = ${peer.PresharedKey || peer.PreSharedKey || ''}
PersistentKeepalive = ${peer.PersistentKeepalive || '25'}
PublicKey = ${peer.PublicKey || ''}`;
}

// ---------- 排除 IP 计算 ----------

/**
 * 如果全局存在 calculateAllowedIPs（由 wasm_exec 注入），
 * 则用它排除服务器 IP，避免 VPN 回环。
 */
function computeAllowedIPs(
  baseAllowedIPs: string,
  serverIP: string,
): string[] {
  const disallowed = `${serverIP}/32`;
  if (typeof (window as any).calculateAllowedIPs === 'function') {
    const result = (window as any).calculateAllowedIPs(baseAllowedIPs, disallowed);
    return result.allowed_ips.split(', ');
  }
  // fallback：直接返回原始值
  return baseAllowedIPs.split(',').map((s) => s.trim());
}

// ---------- 核心接口 ----------

export interface MorphVpnInterface {
  connect(
    wgConfigText: string,
    remoteAddress: string,
    serverInfo: any,
  ): Promise<void>;
  disconnect(): Promise<void>;
  getStatus(): Promise<{
    connected: boolean;
    morphConnected: boolean;
    wgConnected: boolean;
    localPort?: number;
    sessionPort?: number;
  }>;
}

class MorphVpnIOS implements MorphVpnInterface {
  private morphConnected = false;
  private wgConnected = false;
  private localPort: number | null = null;
  private sessionPort: number | null = null;

  /**
   * 连接 VPN
   * @param wgConfigText  WireGuard 配置文本
   * @param remoteAddress 格式 "ip:port:userId"
   * @param serverInfo    服务器信息对象，需包含 encryptionKey
   */
  async connect(
    wgConfigText: string,
    remoteAddress: string,
    serverInfo: any,
  ): Promise<void> {
    if (Capacitor.getPlatform() === 'web') {
      throw new Error('VPN 不支持 Web 平台');
    }

    // 解析 remoteAddress: "ip:port:userId"
    const parts = remoteAddress.split(':');
    const morphHost = parts[0];
    const morphPort = Number(parts[1]);
    const userId = parts[2] || '';

    const encryptionKey: string =
      serverInfo?.encryptionKey || serverInfo?.key || '';
    if (!encryptionKey) {
      throw new Error('缺少加密密钥 (encryptionKey)');
    }

    const obfuscationLayer = serverInfo?.obfuscationLayer ?? 3;
    const paddingLength = serverInfo?.paddingLength ?? 8;
    const templateType = serverInfo?.templateType ?? 1;

    console.log(`[morphVpn_ios] 连接 MorphProtocol → ${morphHost}:${morphPort}`);

    // 1. 启动 MorphProtocol
    const morphResult = await MorphProtocol.connect({
      host: morphHost,
      port: morphPort,
      encryptionKey,
      userId,
      obfuscationLayer,
      paddingLength,
      templateType,
    });

    if (!morphResult.success) {
      throw new Error(`MorphProtocol 连接失败: ${morphResult.message}`);
    }

    this.localPort = morphResult.localPort ?? null;
    console.log(`[morphVpn_ios] MorphProtocol 本地端口: ${this.localPort}`);

    // 2. 等待握手完成
    await this.waitForHandshake();
    this.morphConnected = true;
    console.log(`[morphVpn_ios] 握手完成，会话端口: ${this.sessionPort}`);

    // 3. 改写 WireGuard 配置
    const config = wgConfigToObj(wgConfigText);
    config['Peer'] = config['Peer'] || {};
    config['Peer']['AllowedIPs'] = ['0.0.0.0/0'];

    // 排除服务器 IP
    const baseAllowed = Array.isArray(config['Peer']['AllowedIPs'])
      ? config['Peer']['AllowedIPs'].join(', ')
      : '0.0.0.0/0';
    config['Peer']['AllowedIPs'] = computeAllowedIPs(baseAllowed, morphHost);

    const finalConfig = objToWgConfig(config, this.localPort!);
    console.log(`[morphVpn_ios] WireGuard 配置已改写`);

    // 4. 启动 WireGuard
    const wgResult = await WireGuard.connect({
      config: finalConfig,
      tunnelName: 'MorphVPN',
    });

    if (!wgResult.success) {
      // 回滚 MorphProtocol
      await MorphProtocol.disconnect().catch(() => {});
      this.morphConnected = false;
      throw new Error(`WireGuard 连接失败: ${wgResult.message}`);
    }

    this.wgConnected = true;
    console.log('[morphVpn_ios] VPN 连接成功');
  }

  /**
   * 断开 VPN
   */
  async disconnect(): Promise<void> {
    console.log('[morphVpn_ios] 断开连接...');

    // 先断 WireGuard
    if (this.wgConnected) {
      try {
        await WireGuard.disconnect();
      } catch (e) {
        console.warn('[morphVpn_ios] WireGuard 断开失败:', e);
      }
      this.wgConnected = false;
    }

    // 再断 MorphProtocol
    if (this.morphConnected) {
      try {
        await MorphProtocol.disconnect();
      } catch (e) {
        console.warn('[morphVpn_ios] MorphProtocol 断开失败:', e);
      }
      this.morphConnected = false;
    }

    this.localPort = null;
    this.sessionPort = null;
    console.log('[morphVpn_ios] 已断开');
  }

  /**
   * 获取状态
   */
  async getStatus() {
    return {
      connected: this.morphConnected && this.wgConnected,
      morphConnected: this.morphConnected,
      wgConnected: this.wgConnected,
      localPort: this.localPort ?? undefined,
      sessionPort: this.sessionPort ?? undefined,
    };
  }

  // ---------- 内部方法 ----------

  private waitForHandshake(): Promise<void> {
    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        reject(new Error('MorphProtocol 握手超时 (30s)'));
      }, 30000);

      const handshakeListener = MorphProtocol.addListener(
        'handshakeComplete',
        (data: any) => {
          clearTimeout(timeout);
          this.sessionPort = data.sessionPort;
          handshakeListener.then((h) => h.remove());
          errorListener.then((h) => h.remove());
          resolve();
        },
      );

      const errorListener = MorphProtocol.addListener(
        'statusChanged',
        (data: any) => {
          if (data.status === 'failed') {
            clearTimeout(timeout);
            handshakeListener.then((h) => h.remove());
            errorListener.then((h) => h.remove());
            reject(new Error(data.error || 'MorphProtocol 连接失败'));
          }
        },
      );
    });
  }
}

// ---------- 初始化 ----------

const morphVpnInstance = new MorphVpnIOS();

/**
 * 初始化 window.morphVpn，供 VpnPage 等页面调用。
 * 签名与 Android morphVpn_android.js 一致：
 *   window.morphVpn.connect(configText, "ip:port:userId", serverInfo)
 *   window.morphVpn.disconnect()
 *   window.morphVpn.getStatus()
 */
export function initMorphVpnIOS(): void {
  (window as any).morphVpn = {
    connect: (
      wgConfigText: string,
      remoteAddress: string,
      serverInfo: any,
    ) => morphVpnInstance.connect(wgConfigText, remoteAddress, serverInfo),

    disconnect: () => morphVpnInstance.disconnect(),

    getStatus: () => morphVpnInstance.getStatus(),
  };

  console.log('[morphVpn_ios] window.morphVpn 已初始化');
}

export { morphVpnInstance };
