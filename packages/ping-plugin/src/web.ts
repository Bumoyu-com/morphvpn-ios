import { WebPlugin } from '@capacitor/core';

import type { PingPlugin, PingOptions, PingResult } from './definitions';

export class PingWeb extends WebPlugin implements PingPlugin {
  async ping(options: PingOptions): Promise<PingResult> {
    console.warn('Ping plugin is not supported on web platform');
    return { latency: null };
  }
}
