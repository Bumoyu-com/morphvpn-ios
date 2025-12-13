import { WireGuardConnectOptions } from '@morphvpn/capacitor-wireguard';

export interface ValidationResult {
  valid: boolean;
  error?: string;
}

/**
 * 验证 WireGuard 配置
 */
export function validateWireGuardConfig(config: string): ValidationResult {
  if (!config || config.trim().length === 0) {
    return { valid: false, error: 'WireGuard 配置不能为空' };
  }

  // 检查必需的配置段
  if (!config.includes('[Interface]')) {
    return { valid: false, error: 'WireGuard 配置缺少 [Interface] 段' };
  }

  if (!config.includes('[Peer]')) {
    return { valid: false, error: 'WireGuard 配置缺少 [Peer] 段' };
  }

  // 检查必需的字段
  const requiredFields = ['PrivateKey', 'Address', 'PublicKey', 'Endpoint'];
  for (const field of requiredFields) {
    if (!config.includes(field)) {
      return { valid: false, error: `WireGuard 配置缺少必需字段: ${field}` };
    }
  }

  return { valid: true };
}

/**
 * 验证 MorphProtocol 配置
 */
export function validateMorphProtocolConfig(options: WireGuardConnectOptions): ValidationResult {
  // 如果未启用 MorphProtocol，跳过验证
  if (!options.useMorphProtocol) {
    return { valid: true };
  }

  // 验证加密密钥格式
  if (!options.morphEncryptionKey) {
    return { valid: false, error: 'MorphProtocol 加密密钥不能为空' };
  }

  if (!options.morphEncryptionKey.includes(':')) {
    return { 
      valid: false, 
      error: 'MorphProtocol 加密密钥格式错误（应为 base64key:base64iv）' 
    };
  }

  const [key, iv] = options.morphEncryptionKey.split(':');
  
  if (!key || key.length === 0) {
    return { valid: false, error: 'MorphProtocol 加密密钥的 key 部分为空' };
  }

  if (!iv || iv.length === 0) {
    return { valid: false, error: 'MorphProtocol 加密密钥的 iv 部分为空' };
  }

  // 验证 Base64 格式
  const base64Regex = /^[A-Za-z0-9+/]+=*$/;
  if (!base64Regex.test(key)) {
    return { valid: false, error: 'MorphProtocol 密钥的 key 部分不是有效的 Base64 格式' };
  }

  if (!base64Regex.test(iv)) {
    return { valid: false, error: 'MorphProtocol 密钥的 iv 部分不是有效的 Base64 格式' };
  }

  // 验证服务器地址
  if (!options.morphServerHost || options.morphServerHost.trim().length === 0) {
    return { valid: false, error: 'MorphProtocol 服务器地址不能为空' };
  }

  // 验证服务器端口
  if (!options.morphServerPort || options.morphServerPort <= 0 || options.morphServerPort > 65535) {
    return { 
      valid: false, 
      error: 'MorphProtocol 服务器端口无效（应为 1-65535）' 
    };
  }

  // 验证混淆层数
  if (options.morphLayerCount !== undefined) {
    if (options.morphLayerCount < 1 || options.morphLayerCount > 4) {
      return { 
        valid: false, 
        error: 'MorphProtocol 混淆层数无效（应为 1-4）' 
      };
    }
  }

  // 验证填充长度
  if (options.morphPaddingLength !== undefined) {
    if (options.morphPaddingLength < 1 || options.morphPaddingLength > 16) {
      return { 
        valid: false, 
        error: 'MorphProtocol 填充长度无效（应为 1-16）' 
      };
    }
  }

  return { valid: true };
}

/**
 * 验证完整的连接配置
 */
export function validateConnectOptions(options: WireGuardConnectOptions): ValidationResult {
  // 验证隧道名称
  if (!options.tunnelName || options.tunnelName.trim().length === 0) {
    return { valid: false, error: '隧道名称不能为空' };
  }

  // 验证 WireGuard 配置
  const wgResult = validateWireGuardConfig(options.config);
  if (!wgResult.valid) {
    return wgResult;
  }

  // 验证 MorphProtocol 配置
  const morphResult = validateMorphProtocolConfig(options);
  if (!morphResult.valid) {
    return morphResult;
  }

  return { valid: true };
}

/**
 * 生成配置摘要（用于日志和调试）
 */
export function getConfigSummary(options: WireGuardConnectOptions): string {
  const lines = [
    `隧道名称: ${options.tunnelName}`,
    `配置长度: ${options.config.length} 字节`,
  ];

  if (options.useMorphProtocol) {
    lines.push('MorphProtocol: 已启用');
    lines.push(`  服务器: ${options.morphServerHost}:${options.morphServerPort}`);
    lines.push(`  混淆层数: ${options.morphLayerCount || 3}`);
    lines.push(`  填充长度: ${options.morphPaddingLength || 8}`);
    lines.push(`  密钥长度: ${options.morphEncryptionKey?.length || 0} 字符`);
  } else {
    lines.push('MorphProtocol: 未启用');
  }

  return lines.join('\n');
}
