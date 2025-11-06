import { useEffect } from 'react';
import { useStore } from 'react-redux'
import { HashRouter as Router, Route, Routes } from 'react-router-dom';
import { initialGlobalState } from './store/module';
import { checkStorage } from './components/MyStorage';
import VpnPage from './pages/VpnPage';
import NotFound from './pages/NotFound';
import LoginPage from './pages/LoginPage';
import SignupPage from './pages/SignupPage';
import SVerifyPage from './pages/SVerifyPage';
import RestorePage from './pages/RestorePage';

// 待办事项：
// 密码长度验证，vpn账号名显示

// import 'highlight.js/styles/github.css';

function App() {
  //加载redux
  const store = useStore();
  initialGlobalState();

  const checkNotificationPermission = async () => {
    // 检查并请求通知权限
    if (window.LocalNotifications) {
      console.log('检查并请求通知权限');
      const { display } = await window.LocalNotifications.checkPermissions();
      if (display !== 'granted') {
        await window.LocalNotifications.requestPermissions();
      }
    }
  }

  //初始化
  useEffect(() => {
    window.getStore = store.getState;
    checkStorage();
    window.showNotification = true;
    checkNotificationPermission();
  }, [])
  const wrapComponent = (Component: JSX.Element) => {
    return (
      <div className='bg-gray-950 min-h-screen'>
        <div
          className="pointer-events-none"
          style={{ position: 'fixed', top: '0px', right: '-6vw', width: '100%', height: '100%', zIndex: '1' }}
        >
          <img alt="Page illustration"
            loading="lazy" width="846" height="594"
            decoding="async" data-nimg="1" className="max-w-none"
            src="/page-illustration.svg" />
        </div>
        <div
          className="pointer-events-none"
          style={{ position: 'fixed', bottom: '-50vh', right: '25vw', width: '100%', height: '100%', zIndex: '1' }}
        >
          <img alt="Page illustration"
            loading="lazy" width="846" height="594"
            decoding="async" data-nimg="1" className="max-w-none"
            src="/blurred-shape.svg" />
        </div>
        {Component}
      </div>
    )
  }

  return (
    <Router>
      <Routes>
        <Route path="*" element={wrapComponent(<NotFound />)} />
        <Route path="/" element={wrapComponent(<LoginPage />)} />
        <Route path="/vpn" element={wrapComponent(<VpnPage />)} />
        <Route path="/signup" element={wrapComponent(<SignupPage />)} />
        <Route path="/restore" element={wrapComponent(<RestorePage />)} />
        <Route path="/sverify" element={wrapComponent(<SVerifyPage />)} />

      </Routes>
    </Router>


  );
}

export default App;
