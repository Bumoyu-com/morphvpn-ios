#!/usr/bin/env node

/**
 * MorphProtocol 加密密钥生成器
 * 
 * 此脚本生成用于 MorphProtocol 的 AES-GCM 加密密钥
 * 
 * 使用方法:
 *   node generate-morph-key.js
 * 
 * 或者直接运行:
 *   ./generate-morph-key.js
 */

const crypto = require('crypto');

console.log('═══════════════════════════════════════════════════════');
console.log('  MorphProtocol 加密密钥生成器');
console.log('═══════════════════════════════════════════════════════\n');

// 生成 32 字节（256 位）的密钥
const key = crypto.randomBytes(32).toString('base64');

// 生成 12 字节（96 位）的 IV (Initialization Vector)
const iv = crypto.randomBytes(12).toString('base64');

// 组合密钥（格式：key:iv）
const combinedKey = `${key}:${iv}`;

console.log('✅ 密钥生成成功！\n');

console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log('完整密钥（复制此行用于配置）:');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log(`\x1b[32m${combinedKey}\x1b[0m\n`);

console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log('密钥组成部分:');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log(`密钥 (32字节/256位): ${key}`);
console.log(`IV   (12字节/96位):  ${iv}\n`);

console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log('使用示例:');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log(`
// TypeScript/JavaScript
await WireGuard.connect({
  config: wireguardConfig,
  tunnelName: 'MorphVPN',
  useMorphProtocol: true,
  morphEncryptionKey: '${combinedKey}',
  morphServerHost: 'morph.example.com',
  morphServerPort: 51821
});
`);

console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log('⚠️  安全提示:');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log('1. 请妥善保存此密钥，不要泄露给他人');
console.log('2. 不要将密钥提交到版本控制系统（Git）');
console.log('3. 建议使用环境变量或安全存储来管理密钥');
console.log('4. 定期更换密钥以提高安全性');
console.log('5. 服务器端和客户端必须使用相同的密钥\n');

console.log('═══════════════════════════════════════════════════════\n');
