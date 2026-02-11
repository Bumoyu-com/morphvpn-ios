import React from 'react';
import ReactDOM from 'react-dom/client';
import { Provider } from 'react-redux';
import { I18nextProvider } from 'react-i18next';
import i18n from './i18n';

import App from './App';
import store from './store';

import './css/index.css';

// VPN 连接器由 HTML 层的 morphVpn_ios.js 初始化（<script> 标签加载）
// 不再在 React 中调用 initMorphVpn()

ReactDOM.createRoot(document.getElementById('root') as HTMLElement).render(
  <Provider store={store}>
    {/* <React.StrictMode> */}
      <I18nextProvider i18n={i18n}>
        <App />
      </I18nextProvider>
    {/* </React.StrictMode> */}
  </Provider>
);
