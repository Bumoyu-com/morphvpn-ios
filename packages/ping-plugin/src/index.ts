import { registerPlugin } from '@capacitor/core';

import type { PingPlugin } from './definitions';

const Ping = registerPlugin<PingPlugin>('Ping', {
  web: () => import('./web').then(m => new m.PingWeb()),
});

export * from './definitions';
export { Ping };
