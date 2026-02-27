/**
 * Ping Bridge - 独立的 Ping 插件调用层
 * 通过 window 对象暴露，不依赖 React
 */

(function() {
  'use strict';

  // 等待 Capacitor 加载完成
  function waitForCapacitor() {
    return new Promise((resolve) => {
      if (window.Capacitor && window.Capacitor.Plugins) {
        resolve();
      } else {
        const checkInterval = setInterval(() => {
          if (window.Capacitor && window.Capacitor.Plugins) {
            clearInterval(checkInterval);
            resolve();
          }
        }, 100);
      }
    });
  }

  // Ping 功能封装
  const PingBridge = {
    /**
     * 执行 ping 测试
     * @param {string} address - 目标地址（支持 IP、域名、HTTP/HTTPS URL）
     * @returns {Promise<number|null>} 平均延迟（毫秒）或 null（超时）
     */
    async ping(address) {
      try {
        await waitForCapacitor();
        
        const { Ping } = window.Capacitor.Plugins;
        
        if (!Ping) {
          console.error('Ping plugin not found');
          return null;
        }

        const result = await Ping.ping({ address });
        return result.latency;
      } catch (error) {
        console.error('Ping error:', error);
        return null;
      }
    },

    /**
     * 批量 ping 多个地址
     * @param {string[]} addresses - 地址数组
     * @returns {Promise<Array<{address: string, latency: number|null}>>}
     */
    async pingMultiple(addresses) {
      const results = [];
      
      for (const address of addresses) {
        const latency = await this.ping(address);
        results.push({ address, latency });
      }
      
      return results;
    },

    /**
     * 并发 ping 多个地址
     * @param {string[]} addresses - 地址数组
     * @returns {Promise<Array<{address: string, latency: number|null}>>}
     */
    async pingConcurrent(addresses) {
      const promises = addresses.map(async (address) => {
        const latency = await this.ping(address);
        return { ip:address, avgRtt:latency };
      });
      
      return Promise.all(promises);
    }
  };

  // 暴露到 window 对象
  window.PingBridge = PingBridge;

  console.log('✅ PingBridge loaded and ready');
})();
