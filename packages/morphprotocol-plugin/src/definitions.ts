/**
 * MorphProtocol 连接配置
 */
export interface MorphProtocolConnectOptions {
  /**
   * 远程服务器地址
   */
  host: string;
  
  /**
   * 远程服务器端口 (握手端口，默认 12301)
   */
  port: number;
  
  /**
   * 加密密钥 (格式: base64key:base64iv)
   */
  encryptionKey: string;
  
  /**
   * 用户ID (用于服务端识别)
   */
  userId: string;
  
  /**
   * 混淆层数 (1-4)
   * @default 3
   */
  obfuscationLayer?: number;
  
  /**
   * 填充长度 (1-16)
   * @default 8
   */
  paddingLength?: number;
  
  /**
   * 协议模板类型
   * 0 = 随机选择, 1 = QUIC, 2 = KCP, 3 = Gaming
   * @default 1
   */
  templateType?: number;
  
  /**
   * 本地代理端口 (WireGuard 连接的端口)
   * 如果为 0 或不指定，系统自动分配
   * @default 0
   */
  localProxyPort?: number;

  /**
   * 心跳间隔（毫秒）
   * @default 120000
   */
  heartbeatInterval?: number;

  /**
   * 不活跃超时（毫秒）
   * @default 30000
   */
  inactivityTimeout?: number;

  /**
   * 握手最大重试次数
   * @default 10
   */
  maxRetries?: number;

  /**
   * 握手重试间隔（毫秒）
   * @default 5000
   */
  handshakeInterval?: number;
}

/**
 * MorphProtocol 连接状态
 */
export interface MorphProtocolStatus {
  /**
   * 连接状态
   */
  status: 'disconnected' | 'connecting' | 'connected' | 'failed';
  
  /**
   * 本地代理端口 (WireGuard 应连接到此端口)
   */
  localPort?: number;
  
  /**
   * 远程会话端口
   */
  sessionPort?: number;
  
  /**
   * 错误信息（如果有）
   */
  error?: string;
}

/**
 * 发送数据选项
 */
export interface MorphProtocolSendOptions {
  /**
   * 要发送的数据 (Base64 编码)
   */
  data: string;
}

/**
 * 接收数据结果
 */
export interface MorphProtocolReceiveResult {
  /**
   * 接收到的数据 (Base64 编码)
   */
  data: string;
}

/**
 * 通用响应
 */
export interface MorphProtocolResponse {
  /**
   * 操作是否成功
   */
  success: boolean;
  
  /**
   * 消息
   */
  message?: string;
  
  /**
   * 本地代理端口 (连接成功后返回)
   */
  localPort?: number;
  
  /**
   * 远程会话端口 (握手成功后返回)
   */
  sessionPort?: number;
}

/**
 * MorphProtocol 插件接口
 */
export interface MorphProtocolPlugin {
  /**
   * 连接到 MorphProtocol 服务器
   * 
   * 连接流程:
   * 1. 启动本地 UDP 代理 (NWListener)
   * 2. 连接到远程服务器并完成握手
   * 3. 返回本地代理端口，WireGuard 应将 Endpoint 设置为 127.0.0.1:localPort
   * 
   * @example
   * ```typescript
   * const result = await MorphProtocol.connect({
   *   host: 'vpn.example.com',
   *   port: 12301,
   *   encryptionKey: 'base64key:base64iv',
   *   userId: 'user123',
   *   obfuscationLayer: 3,
   *   paddingLength: 8,
   *   templateType: 1
   * });
   * 
   * // WireGuard 配置中使用:
   * // Endpoint = 127.0.0.1:${result.localPort}
   * ```
   */
  connect(options: MorphProtocolConnectOptions): Promise<MorphProtocolResponse>;
  
  /**
   * 断开连接
   */
  disconnect(): Promise<MorphProtocolResponse>;
  
  /**
   * 获取连接状态
   */
  getStatus(): Promise<MorphProtocolStatus>;
  
  /**
   * 发送数据 (用于测试)
   */
  send(options: MorphProtocolSendOptions): Promise<MorphProtocolResponse>;

  /**
   * 测试混淆功能（与 Android testObfuscation 对齐）
   */
  testObfuscation(): Promise<{ success: boolean; message: string }>;
  
  /**
   * 添加接收数据监听器
   */
  addListener(
    eventName: 'dataReceived',
    listenerFunc: (data: MorphProtocolReceiveResult) => void,
  ): Promise<any>;
  
  /**
   * 添加状态变化监听器
   */
  addListener(
    eventName: 'statusChanged',
    listenerFunc: (status: MorphProtocolStatus) => void,
  ): Promise<any>;
  
  /**
   * 添加本地端口就绪监听器
   */
  addListener(
    eventName: 'localPortReady',
    listenerFunc: (data: { port: number }) => void,
  ): Promise<any>;
  
  /**
   * 添加握手完成监听器
   */
  addListener(
    eventName: 'handshakeComplete',
    listenerFunc: (data: { sessionPort: number }) => void,
  ): Promise<any>;
  
  /**
   * 移除所有监听器
   */
  removeAllListeners(): Promise<void>;
}
