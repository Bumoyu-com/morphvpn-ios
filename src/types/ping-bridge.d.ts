/**
 * PingBridge 全局类型声明
 * 用于在 TypeScript 中使用 window.PingBridge
 */

interface PingResult {
  address: string;
  latency: number | null;
}

interface PingBridge {
  /**
   * 执行 ping 测试
   * @param address - 目标地址（支持 IP、域名、HTTP/HTTPS URL）
   * @returns 平均延迟（毫秒）或 null（超时）
   */
  ping(address: string): Promise<number | null>;

  /**
   * 批量 ping 多个地址（顺序执行）
   * @param addresses - 地址数组
   * @returns 结果数组
   */
  pingMultiple(addresses: string[]): Promise<PingResult[]>;

  /**
   * 并发 ping 多个地址（同时执行）
   * @param addresses - 地址数组
   * @returns 结果数组
   */
  pingConcurrent(addresses: string[]): Promise<PingResult[]>;
}

interface Window {
  PingBridge: PingBridge;
}
