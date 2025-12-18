import { WebPlugin } from '@capacitor/core';

import type {
  MorphProtocolPlugin,
  MorphProtocolConnectOptions,
  MorphProtocolStatus,
  MorphProtocolSendOptions,
  MorphProtocolResponse,
} from './definitions';

export class MorphProtocolWeb extends WebPlugin implements MorphProtocolPlugin {
  async connect(options: MorphProtocolConnectOptions): Promise<MorphProtocolResponse> {
    console.log('MorphProtocol connect', options);
    return {
      success: false,
      message: 'MorphProtocol is not supported on web platform',
    };
  }

  async disconnect(): Promise<MorphProtocolResponse> {
    return {
      success: false,
      message: 'MorphProtocol is not supported on web platform',
    };
  }

  async getStatus(): Promise<MorphProtocolStatus> {
    return {
      status: 'disconnected',
      error: 'MorphProtocol is not supported on web platform',
    };
  }

  async send(options: MorphProtocolSendOptions): Promise<MorphProtocolResponse> {
    console.log('MorphProtocol send', options);
    return {
      success: false,
      message: 'MorphProtocol is not supported on web platform',
    };
  }
}
