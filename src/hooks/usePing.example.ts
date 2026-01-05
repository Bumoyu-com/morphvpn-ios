/**
 * usePing Hook 示例
 * 
 * 使用方法：
 * 1. 复制此文件为 usePing.ts
 * 2. 在组件中导入使用
 */

import { useState, useCallback } from 'react';

interface PingState {
  latency: number | null;
  loading: boolean;
  error: string | null;
}

/**
 * Ping Hook
 * @param address - 目标地址
 * @returns Ping 状态和重新测试函数
 */
export function usePing(address: string) {
  const [state, setState] = useState<PingState>({
    latency: null,
    loading: false,
    error: null,
  });

  const ping = useCallback(async () => {
    setState({ latency: null, loading: true, error: null });

    try {
      const latency = await window.PingBridge.ping(address);
      setState({ latency, loading: false, error: null });
    } catch (error) {
      setState({
        latency: null,
        loading: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }, [address]);

  return { ...state, ping };
}

/**
 * 批量 Ping Hook
 * @param addresses - 地址数组
 * @returns Ping 结果和重新测试函数
 */
export function usePingMultiple(addresses: string[]) {
  const [results, setResults] = useState<Array<{ address: string; latency: number | null }>>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const ping = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const results = await window.PingBridge.pingConcurrent(addresses);
      setResults(results);
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  }, [addresses]);

  return { results, loading, error, ping };
}

/**
 * 使用示例：
 * 
 * ```tsx
 * import { usePing, usePingMultiple } from './hooks/usePing';
 * 
 * function ServerStatus() {
 *   const { latency, loading, error, ping } = usePing('8.8.8.8');
 * 
 *   useEffect(() => {
 *     ping();
 *   }, [ping]);
 * 
 *   return (
 *     <div>
 *       {loading && <span>测试中...</span>}
 *       {error && <span>错误: {error}</span>}
 *       {latency !== null && <span>延迟: {latency} ms</span>}
 *       {latency === null && !loading && <span>超时</span>}
 *       <button onClick={ping}>重新测试</button>
 *     </div>
 *   );
 * }
 * 
 * function MultiServerStatus() {
 *   const servers = ['8.8.8.8', '1.1.1.1', 'google.com'];
 *   const { results, loading, error, ping } = usePingMultiple(servers);
 * 
 *   useEffect(() => {
 *     ping();
 *   }, [ping]);
 * 
 *   return (
 *     <div>
 *       {loading && <div>测试中...</div>}
 *       {error && <div>错误: {error}</div>}
 *       {results.map(result => (
 *         <div key={result.address}>
 *           {result.address}: {
 *             result.latency !== null 
 *               ? `${result.latency} ms` 
 *               : '超时'
 *           }
 *         </div>
 *       ))}
 *       <button onClick={ping}>重新测试</button>
 *     </div>
 *   );
 * }
 * ```
 */
