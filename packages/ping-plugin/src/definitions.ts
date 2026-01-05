/**
 * Ping 选项
 */
export interface PingOptions {
  /**
   * 目标地址 (支持 IP、域名、HTTP/HTTPS URL)
   */
  address: string;
}

/**
 * Ping 结果
 */
export interface PingResult {
  /**
   * 平均延迟（毫秒），超时返回 null
   */
  latency: number | null;
}

/**
 * Ping 插件接口
 */
export interface PingPlugin {
  /**
   * 执行 ping 测试
   * - 自动 ping 3次并计算平均值
   * - 每次超时时间为 3 秒
   * - 支持 IP 地址、域名、HTTP/HTTPS URL
   */
  ping(options: PingOptions): Promise<PingResult>;
}
