/**
 * iOS 端 morphVpn 调用接口
 *
 * 在 HTML 中通过 <script src="/morphVpn_ios.js"></script> 引入。
 * 通过 Capacitor.Plugins 直接调用原生插件，无需 import。
 *
 * 连接流程：MorphProtocol 握手 → 获取本地代理端口 → 改写 WireGuard Endpoint → 启动 WireGuard
 *
 * 调用方式（与 Android morphVpn_android.js 一致）：
 *   window.morphVpn.connect(wgConfigText, "ip:port:userId", { encryptionKey, ... })
 *   window.morphVpn.disconnect()
 *   window.morphVpn.getStatus()
 */

(function () {
  'use strict';

  // ========== WireGuard 配置解析/序列化 ==========

  function wgConfigToObj(input) {
    var lines = input.split('\n');
    var result = {};
    var currentSection = null;

    for (var i = 0; i < lines.length; i++) {
      var trimmed = lines[i].trim();
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        currentSection = trimmed.slice(1, -1);
        result[currentSection] = {};
      } else if (currentSection && trimmed.includes(' = ')) {
        var eqIndex = trimmed.indexOf(' = ');
        var key = trimmed.substring(0, eqIndex).trim();
        var value = trimmed.substring(eqIndex + 3).trim();
        if (key === 'DNS' || key === 'AllowedIPs') {
          result[currentSection][key] = value.split(',').map(function (s) { return s.trim(); });
        } else {
          result[currentSection][key] = value;
        }
      }
    }
    return result;
  }

  function objToWgConfig(config, endPort) {
    var iface = config['Interface'] || {};
    var peer = config['Peer'] || {};
    var dns = Array.isArray(iface.DNS) ? iface.DNS.join(',') : (iface.DNS || '');
    var allowedIPs = Array.isArray(peer.AllowedIPs)
      ? peer.AllowedIPs.join(',')
      : (peer.AllowedIPs || '0.0.0.0/0');

    return '[Interface]\n' +
      'Address = ' + (iface.Address || '') + '\n' +
      'DNS = ' + dns + '\n' +
      'PrivateKey = ' + (iface.PrivateKey || '') + '\n' +
      'ListenPort = 51820\n' +
      '\n' +
      '[Peer]\n' +
      'AllowedIPs = ' + allowedIPs + '\n' +
      'Endpoint = 127.0.0.1:' + endPort + '\n' +
      'PresharedKey = ' + (peer.PresharedKey || peer.PreSharedKey || '') + '\n' +
      'PersistentKeepalive = ' + (peer.PersistentKeepalive || '25') + '\n' +
      'PublicKey = ' + (peer.PublicKey || '');
  }

  // ========== 排除 IP 计算 ==========

  /**
   * 纯 JS 实现：从 0.0.0.0/0 中排除一个 /32 地址
   * 将 0.0.0.0/0 拆分为不包含 excludeIP 的 CIDR 列表
   */
  function excludeIPFromAllRoutes(excludeIP) {
    var parts = excludeIP.split('.');
    var ip = ((parseInt(parts[0]) << 24) | (parseInt(parts[1]) << 16) |
              (parseInt(parts[2]) << 8) | parseInt(parts[3])) >>> 0;

    var result = [];
    var start = 0;
    var bits = 32;

    // 逐 bit 缩小范围，每次排除包含目标 IP 的那一半，保留另一半
    for (var i = 0; i < bits; i++) {
      var mask = (0xFFFFFFFF << (31 - i)) >>> 0;
      var prefix = (ip & mask) >>> 0;
      var bit = (ip >>> (31 - i)) & 1;

      // 保留不包含目标 IP 的那一半
      var otherHalf;
      if (bit === 0) {
        otherHalf = (prefix | (1 << (31 - i))) >>> 0;
      } else {
        otherHalf = (prefix & ~(1 << (31 - i))) >>> 0;
      }

      var cidr = ((otherHalf >>> 24) & 0xFF) + '.' +
                 ((otherHalf >>> 16) & 0xFF) + '.' +
                 ((otherHalf >>> 8) & 0xFF) + '.' +
                 (otherHalf & 0xFF) + '/' + (i + 1);
      result.push(cidr);
    }

    return result;
  }

  /**
   * 判断 CIDR 是否包含某个 IP
   */
  function cidrContainsIP(cidr, ip) {
    var parts = cidr.split('/');
    var prefix = ipToInt(parts[0]);
    var bits = parseInt(parts[1]);
    var mask = bits === 0 ? 0 : (0xFFFFFFFF << (32 - bits)) >>> 0;
    var target = ipToInt(ip);
    return (prefix & mask) === (target & mask);
  }

  /**
   * 从一个 CIDR 中排除一个 /32 IP，返回不包含该 IP 的 CIDR 列表
   */
  function excludeIPFromCIDR(cidr, excludeIP) {
    var parts = cidr.split('/');
    var prefix = ipToInt(parts[0]);
    var prefixLen = parseInt(parts[1]);
    var target = ipToInt(excludeIP);
    var result = [];

    for (var i = prefixLen; i < 32; i++) {
      var bit = (target >>> (31 - i)) & 1;
      var otherHalf;
      if (bit === 0) {
        otherHalf = (prefix | (1 << (31 - i))) >>> 0;
      } else {
        otherHalf = (prefix & ~(1 << (31 - i))) >>> 0;
      }
      result.push(intToIP(otherHalf) + '/' + (i + 1));
      // 缩小 prefix 到包含 target 的那一半
      prefix = (prefix & ((0xFFFFFFFF << (31 - i)) >>> 0)) >>> 0;
      if (bit === 1) {
        prefix = (prefix | (1 << (31 - i))) >>> 0;
      }
    }
    return result;
  }

  function ipToInt(ip) {
    var p = ip.split('.');
    return ((parseInt(p[0]) << 24) | (parseInt(p[1]) << 16) |
            (parseInt(p[2]) << 8) | parseInt(p[3])) >>> 0;
  }

  function intToIP(n) {
    return ((n >>> 24) & 0xFF) + '.' + ((n >>> 16) & 0xFF) + '.' +
           ((n >>> 8) & 0xFF) + '.' + (n & 0xFF);
  }

  // ========== 状态 ==========

  var morphConnected = false;
  var wgConnected = false;
  var localPort = null;
  var sessionPort = null;

  // ========== 获取 Capacitor 插件 ==========

  function getMorphProtocol() {
    return window.Capacitor && window.Capacitor.Plugins && window.Capacitor.Plugins.MorphProtocol;
  }

  function getWireGuard() {
    return window.Capacitor && window.Capacitor.Plugins && window.Capacitor.Plugins.WireGuard;
  }

  // ========== 等待握手 ==========

  // 返回 Promise<handshakeData>，包含 sessionPort、obfuscationKey、templateId、clientID
  function waitForHandshake() {
    var MorphProtocol = getMorphProtocol();
    return new Promise(function (resolve, reject) {
      var timer = setTimeout(function () {
        reject(new Error('MorphProtocol 握手超时 (30s)'));
      }, 30000);

      var handshakeHandle = null;
      var errorHandle = null;

      function cleanup() {
        clearTimeout(timer);
        if (handshakeHandle && typeof handshakeHandle.remove === 'function') {
          handshakeHandle.remove();
        }
        if (errorHandle && typeof errorHandle.remove === 'function') {
          errorHandle.remove();
        }
      }

      if (MorphProtocol && typeof MorphProtocol.addListener === 'function') {
        var hPromise = MorphProtocol.addListener('handshakeComplete', function (data) {
          sessionPort = data.sessionPort;
          cleanup();
          resolve(data);  // 返回完整握手数据
        });
        // addListener 可能返回 Promise<PluginListenerHandle> 或直接返回 handle
        if (hPromise && typeof hPromise.then === 'function') {
          hPromise.then(function (h) { handshakeHandle = h; });
        } else {
          handshakeHandle = hPromise;
        }

        var ePromise = MorphProtocol.addListener('statusChanged', function (data) {
          if (data.status === 'failed') {
            cleanup();
            reject(new Error(data.error || 'MorphProtocol 连接失败'));
          }
        });
        if (ePromise && typeof ePromise.then === 'function') {
          ePromise.then(function (h) { errorHandle = h; });
        } else {
          errorHandle = ePromise;
        }
      } else {
        clearTimeout(timer);
        reject(new Error('MorphProtocol 插件不可用'));
      }
    });
  }

  // ========== connect ==========

  // 第三个参数 remotePublicKey 是 encryptionKey 字符串（与 Android morphVpn_android.js 一致）
  async function connect(wgConfigText, remoteAddress, remotePublicKey) {
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

    var encryptionKey = remotePublicKey || '';
    if (!encryptionKey) {
      throw new Error('缺少加密密钥 (encryptionKey)');
    }

    var obfuscationLayer = 3;
    var paddingLength = 8;
    var templateType = 1;

    console.log('[morphVpn_ios] 连接 MorphProtocol → ' + morphHost + ':' + morphPort);

    // 0. 清空旧的 Extension 日志
    await clearExtensionLog();

    // 1. 启动 MorphProtocol
    var morphResult = await MorphProtocol.connect({
      host: morphHost,
      port: morphPort,
      encryptionKey: encryptionKey,
      userId: userId,
      obfuscationLayer: obfuscationLayer,
      paddingLength: paddingLength,
      templateType: templateType
    });

    if (!morphResult.success) {
      throw new Error('MorphProtocol 连接失败: ' + (morphResult.message || ''));
    }

    localPort = morphResult.localPort || null;
    console.log('[morphVpn_ios] MorphProtocol 本地端口: ' + localPort);

    // 2. 等待握手完成，获取会话参数
    var handshakeData = await waitForHandshake();
    morphConnected = true;
    console.log('[morphVpn_ios] 握手完成，会话端口: ' + sessionPort +
      ', key: ' + handshakeData.obfuscationKey +
      ', templateId: ' + handshakeData.templateId +
      ', clientID: ' + (handshakeData.clientID || '').substring(0, 8) + '...');

    // 3. 改写 WireGuard 配置（与 Android 对齐）
    var config = wgConfigToObj(wgConfigText);
    config['Peer'] = config['Peer'] || {};

    // 先重置为仅 IPv4（与 Android 一致，去掉 ::/0）
    // 排除服务器 IP（避免路由回环）和 127.0.0.0/8（loopback，Extension 内部代理需要）
    //
    // 0.0.0.0/0 拆分为不含 127.0.0.0/8 的 CIDR：
    //   0.0.0.0/1     (0-127)   → 再拆: 0.0.0.0/2 (0-63) + 64.0.0.0/3 (64-95) + 96.0.0.0/4 (96-111) + 112.0.0.0/5 (112-119) + 120.0.0.0/6 (120-123) + 124.0.0.0/7 (124-125) + 126.0.0.0/8 (126)
    //   128.0.0.0/1   (128-255)
    // 即排除 127.0.0.0/8 后的等价路由
    var baseRoutes = [
      '0.0.0.0/2', '64.0.0.0/3', '96.0.0.0/4', '112.0.0.0/5',
      '120.0.0.0/6', '124.0.0.0/7', '126.0.0.0/8',
      '128.0.0.0/1'
    ];

    // 从 baseRoutes 中排除服务器 IP
    var finalRoutes = [];
    for (var ri = 0; ri < baseRoutes.length; ri++) {
      var cidr = baseRoutes[ri];
      if (cidrContainsIP(cidr, morphHost)) {
        // 这个 CIDR 包含服务器 IP，需要进一步拆分排除
        var subRoutes = excludeIPFromCIDR(cidr, morphHost);
        finalRoutes = finalRoutes.concat(subRoutes);
      } else {
        finalRoutes.push(cidr);
      }
    }
    config['Peer'] = config['Peer'] || {};
    config['Peer']['AllowedIPs'] = finalRoutes;
    console.log('[morphVpn_ios] AllowedIPs (' + finalRoutes.length + ' routes), excluded: 127.0.0.0/8 + ' + morphHost);

    // Endpoint 设为远程服务器（Extension 中会替换为本地代理端口）
    var finalConfig = objToWgConfig(config, morphPort);
    console.log('[morphVpn_ios] Final WG config:\n' + finalConfig);

    // 4. 构建 MorphProtocol 配置传给 Network Extension（含 fnInitor 同步混淆参数）
    var morphConfigForExt = JSON.stringify({
      host: morphHost,
      sessionPort: sessionPort,
      key: handshakeData.obfuscationKey || 0,
      layer: obfuscationLayer,
      padding: paddingLength,
      templateId: handshakeData.templateId || templateType,
      clientID: handshakeData.clientID || '',
      fnInitor: {
        substitutionTable: handshakeData.substitutionTable || [],
        randomValue: handshakeData.randomValue || 0
      }
    });
    console.log('[morphVpn_ios] morphConfig for extension: ' + morphConfigForExt);

    // 5. 启动 WireGuard（带 MorphProtocol 配置）
    var wgResult = await WireGuard.connect({
      config: finalConfig,
      tunnelName: 'MorphVPN',
      morphConfig: morphConfigForExt
    });

    if (!wgResult.success) {
      // 回滚 MorphProtocol
      try { await MorphProtocol.disconnect(); } catch (e) { /* ignore */ }
      morphConnected = false;
      throw new Error('WireGuard 连接失败: ' + (wgResult.message || ''));
    }

    wgConnected = true;
    console.log('[morphVpn_ios] VPN 连接成功');

    // 延迟 3 秒后读取 Extension 日志（等待 Extension 启动完成）
    setTimeout(async function () {
      var extLog = await getExtensionLog();
      console.log('[morphVpn_ios] === Extension 日志 ===\n' + extLog);
    }, 3000);
  }

  // ========== disconnect ==========

  async function disconnect() {
    console.log('[morphVpn_ios] 断开连接...');
    var WireGuard = getWireGuard();
    var MorphProtocol = getMorphProtocol();

    // 先断 WireGuard
    if (wgConnected && WireGuard) {
      try { await WireGuard.disconnect(); } catch (e) {
        console.warn('[morphVpn_ios] WireGuard 断开失败:', e);
      }
      wgConnected = false;
    }

    // 再断 MorphProtocol
    if (morphConnected && MorphProtocol) {
      try { await MorphProtocol.disconnect(); } catch (e) {
        console.warn('[morphVpn_ios] MorphProtocol 断开失败:', e);
      }
      morphConnected = false;
    }

    localPort = null;
    sessionPort = null;
    console.log('[morphVpn_ios] 已断开');
  }

  // ========== getStatus ==========

  function getStatus() {
    return Promise.resolve({
      connected: morphConnected && wgConnected,
      morphConnected: morphConnected,
      wgConnected: wgConnected,
      localPort: localPort,
      sessionPort: sessionPort
    });
  }

  // ========== 读取 Extension 日志 ==========

  async function getExtensionLog() {
    var WireGuard = getWireGuard();
    if (!WireGuard) return '(WireGuard plugin unavailable)';
    try {
      var result = await WireGuard.getExtensionLog();
      return result.log || '';
    } catch (e) {
      return '(error: ' + e.message + ')';
    }
  }

  async function clearExtensionLog() {
    var WireGuard = getWireGuard();
    if (!WireGuard) return;
    try { await WireGuard.clearExtensionLog(); } catch (e) { /* ignore */ }
  }

  // ========== 挂载到 window ==========

  window.morphVpn = {
    connect: connect,
    disconnect: disconnect,
    getStatus: getStatus,
    getExtensionLog: getExtensionLog,
    clearExtensionLog: clearExtensionLog
  };

  console.log('[morphVpn_ios] window.morphVpn 已初始化');
})();
