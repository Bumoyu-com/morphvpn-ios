import React from 'react';
import ReactDOM from 'react-dom/client';
import { Provider } from 'react-redux';
import { I18nextProvider } from 'react-i18next';
import i18n from './i18n';

import App from './App';
import store from './store';

import './css/index.css';

ReactDOM.createRoot(document.getElementById('root') as HTMLElement).render(
  <Provider store={store}>
    {/* <React.StrictMode> */}
      <I18nextProvider i18n={i18n}>
        <App />
      </I18nextProvider>
    {/* </React.StrictMode> */}
  </Provider>
);
