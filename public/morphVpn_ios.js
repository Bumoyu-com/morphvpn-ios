/**
 * iOS 端 morphVpn 调用接口（新架构）
 *
 * MorphProtocol 代理逻辑运行在 Network Extension 进程内，
 * 解决 iOS 进程隔离导致的 localhost UDP 不可达问题。
 *
 * 连接流程：
 *   1. MorphProtocol.connect() → 验证参数，返回 morphConfig JSON
 *   2. WireGuard.connect(config, tunnelName, morphConfig) → Extension 内部完成：
 *      握手 → 本地代理 → 改写 Endpoint/AllowedIPs → 启动 WireGuard
 *
 * 调用方式（与 Android morphVpn_android.js 一致）：
 *   window.morphVpn.connect(wgConfigText, "ip:port:userId", encryptionKey)
 *   window.morphVpn.disconnect()
 *   window.morphVpn.getStatus()
 */

(function () {
  'use strict';

  var TAG = '[morphVpn_ios]';

  // ========== 状态 ==========

  var connected = false;

  // ========== 获取 Capacitor 插件 ==========

  function getMorphProtocol() {
    return window.Capacitor && window.Capacitor.Plugins && window.Capacitor.Plugins.MorphProtocol;
  }

  function getWireGuard() {
    return window.Capacitor && window.Capacitor.Plugins && window.Capacitor.Plugins.WireGuard;
  }

  // ========== connect ==========

  /**
   * @param {string} wgConfigText - 原始 WireGuard 配置文本
   * @param {string} remoteAddress - "ip:port:userId" 格式
   * @param {string} encryptionKey - 加密密钥字符串
   */
  async function connect(wgConfigText, remoteAddress, encryptionKey) {
    var MorphProtocol = getMorphProtocol();
    var WireGuard = getWireGuard();

    if (!MorphProtocol) {
      throw new Error('MorphProtocol 插件不可用');
    }
    if (!WireGuard) {
      throw new Error('WireGuard 插件不可用');
    }

    // 解析 remoteAddress: "ip:port:userId"
    var parts = remoteAddress.split(':');
    var morphHost = parts[0];
    var morphPort = Number(parts[1]);
    var userId = parts[2] || '';

    // encryptionKey 可能是字符串或对象
    var key = '';
    if (typeof encryptionKey === 'string') {
      key = encryptionKey;
    } else if (encryptionKey && typeof encryptionKey === 'object') {
      key = encryptionKey.encryptionKey || encryptionKey.key || encryptionKey.info || '';
    }

    if (!key) {
      throw new Error('缺少加密密钥 (encryptionKey)');
    }

    console.log(TAG, '连接开始 →', morphHost + ':' + morphPort, 'userId=' + userId);

    // 1. 调用 MorphProtocol.connect() 获取 morphConfig JSON
    //    新架构下这只做参数验证，不做网络操作
    console.log(TAG, '步骤1: 构建 MorphProtocol 配置...');
    var morphResult = await MorphProtocol.connect({
      host: morphHost,
      port: morphPort,
      encryptionKey: key,
      userId: userId,
      obfuscationLayer: 3,
      paddingLength: 8,
      templateType: 1
    });

    if (!morphResult.success || !morphResult.morphConfig) {
      throw new Error('MorphProtocol 配置失败: ' + (morphResult.message || ''));
    }

    var morphConfigJSON = morphResult.morphConfig;
    console.log(TAG, '步骤1 完成: morphConfig 已生成, message=' + morphResult.message);

    // 打印 morphConfig 内容（调试用）
    try {
      var parsed = JSON.parse(morphConfigJSON);
      console.log(TAG, '  morphConfig: host=' + parsed.host + ':' + parsed.port +
        ' layer=' + parsed.obfuscationLayer + ' tpl=' + parsed.templateType +
        ' userId=' + (parsed.userId || '').substring(0, 8) + '...');
    } catch (e) {
      console.log(TAG, '  morphConfig (raw):', morphConfigJSON.substring(0, 100));
    }

    // 2. 将原始 WireGuard 配置 + morphConfig 一起传给 WireGuard.connect()
    //    Extension 内部会：解析 morph_config → 启动 MorphUDPClient → 握手 →
    //    改写 Endpoint 为 127.0.0.1:localPort → 排除 127.0.0.0/8 → 启动 WireGuard
    console.log(TAG, '步骤2: 启动 WireGuard (含 MorphProtocol)...');
    console.log(TAG, '  wgConfig 长度:', wgConfigText.length, 'bytes');
    console.log(TAG, '  morphConfig 长度:', morphConfigJSON.length, 'bytes');

    var wgResult = await WireGuard.connect({
      config: wgConfigText,
      tunnelName: 'MorphVPN',
      morphConfig: morphConfigJSON
    });

    if (!wgResult.success) {
      // 清理
      try { await MorphProtocol.disconnect(); } catch (e) { /* ignore */ }
      throw new Error('WireGuard 连接失败: ' + (wgResult.message || ''));
    }

    connected = true;
    console.log(TAG, '步骤2 完成: VPN 连接成功');
  }

  // ========== disconnect ==========

  async function disconnect() {
    console.log(TAG, '断开连接...');
    var WireGuard = getWireGuard();
    var MorphProtocol = getMorphProtocol();

    // 断开 WireGuard（Extension 的 stopTunnel 会自动清理 MorphProtocol）
    if (WireGuard) {
      try {
        await WireGuard.disconnect();
        console.log(TAG, 'WireGuard 已断开');
      } catch (e) {
        console.warn(TAG, 'WireGuard 断开失败:', e);
      }
    }

    // 清理 MorphProtocol 状态
    if (MorphProtocol) {
      try { await MorphProtocol.disconnect(); } catch (e) { /* ignore */ }
    }

    connected = false;
    console.log(TAG, '已断开');
  }

  // ========== getStatus ==========

  function getStatus() {
    return Promise.resolve({
      connected: connected,
      morphConnected: connected,
      wgConnected: connected
    });
  }

  // ========== readExtensionLog ==========

  /**
   * 读取 Extension 进程的共享日志（通过 App Group 容器）
   * 用于调试 Extension 内部的 MorphProtocol 和 WireGuard 行为
   */
  async function readExtensionLog() {
    var WireGuard = getWireGuard();
    if (!WireGuard) {
      return 'WireGuard plugin not available';
    }
    try {
      var result = await WireGuard.readExtensionLog();
      return result.log || '';
    } catch (e) {
      return 'Error reading log: ' + e.message;
    }
  }

  // ========== 挂载到 window ==========

  window.morphVpn = {
    connect: connect,
    disconnect: disconnect,
    getStatus: getStatus,
    readExtensionLog: readExtensionLog
  };

  console.log(TAG, 'window.morphVpn 已初始化 (Extension 内置架构)');
})();
