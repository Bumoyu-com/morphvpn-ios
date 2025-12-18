/**
 * MorphProtocol 连接配置
 */
export interface MorphProtocolConnectOptions {
  /**
   * 服务器地址
   */
  host: string;
  
  /**
   * 服务器端口
   */
  port: number;
  
  /**
   * 加密密钥 (格式: base64key:base64iv)
   */
  encryptionKey: string;
  
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
   * 0 = None, 1 = QUIC, 2 = KCP, 3 = Gaming
   * @default 1
   */
  templateType?: number;
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
}

/**
 * MorphProtocol 插件接口
 */
export interface MorphProtocolPlugin {
  /**
   * 连接到 MorphProtocol 服务器
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
   * 发送数据
   */
  send(options: MorphProtocolSendOptions): Promise<MorphProtocolResponse>;
  
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
   * 移除所有监听器
   */
  removeAllListeners(): Promise<void>;
}
