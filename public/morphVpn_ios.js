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

      // Capacitor 原生事件监听
      if (MorphProtocol && typeof MorphProtocol.addListener === 'function') {
        var hPromise = MorphProtocol.addListener('handshakeComplete', function (data) {
          sessionPort = data.sessionPort;
          cleanup();
          resolve();
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

    // 2. 等待握手完成
    await waitForHandshake();
    morphConnected = true;
    console.log('[morphVpn_ios] 握手完成，会话端口: ' + sessionPort);

    // 3. 改写 WireGuard 配置（与 Android 对齐）
    var config = wgConfigToObj(wgConfigText);
    config['Peer'] = config['Peer'] || {};

    // 先重置为仅 IPv4（与 Android 一致，去掉 ::/0）
    config['Peer']['AllowedIPs'] = ['0.0.0.0/0'];

    // 排除服务器 IP，避免路由回环
    var disallowedIPs = morphHost + '/32';
    if (typeof window.calculateAllowedIPs === 'function') {
      var calcResult = window.calculateAllowedIPs(
        config['Peer']['AllowedIPs'].join(', '),
        disallowedIPs
      );
      config['Peer']['AllowedIPs'] = calcResult.allowed_ips.split(', ');
    }
    console.log('[morphVpn_ios] AllowedIPs: ' + config['Peer']['AllowedIPs'].join(', '));

    var finalConfig = objToWgConfig(config, localPort);
    console.log('[morphVpn_ios] WireGuard 配置已改写');

    // 4. 启动 WireGuard
    var wgResult = await WireGuard.connect({
      config: finalConfig,
      tunnelName: 'MorphVPN'
    });

    if (!wgResult.success) {
      // 回滚 MorphProtocol
      try { await MorphProtocol.disconnect(); } catch (e) { /* ignore */ }
      morphConnected = false;
      throw new Error('WireGuard 连接失败: ' + (wgResult.message || ''));
    }

    wgConnected = true;
    console.log('[morphVpn_ios] VPN 连接成功');
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

  // ========== 挂载到 window ==========

  window.morphVpn = {
    connect: connect,
    disconnect: disconnect,
    getStatus: getStatus
  };

  console.log('[morphVpn_ios] window.morphVpn 已初始化');
})();
