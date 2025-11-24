import { Button, message } from 'antd';
import { Capacitor } from '@capacitor/core';
import { useWireGuard } from '../hooks/useWireGuard';
import { PluginDebug } from './PluginDebug';

export function VPNComponent() {
    const myConfig = `[Interface]
PrivateKey = CCZOUqP86rtu9Nn86NAstjdhf9A4FH5JDpBNvVBibV8=
Address = 10.8.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = MHFCzcQ9ywEeTelvtgHPTYCpjIG8/mMWoD2k2BFfIT4=
PresharedKey = cEKYHxmOzBSoCPjr8Q7kiHife6pUyWH9S2M9NUC2vrw=
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 0
Endpoint = 43.138.0.94:51820
`;

    const { status, isConnected, connect, disconnect } = useWireGuard();
    const platform = Capacitor.getPlatform();

    const handleConnect = async () => {
        try {
            message.info(`当前平台: ${platform}`, 2);
            
            if (platform === 'web') {
                message.warning('WireGuard 不支持 Web 平台，请在 iOS 设备上测试', 3);
                return;
            }
            
            message.loading('正在连接 WireGuard VPN...', 0);
            await connect(myConfig, 'TestVPN');
            message.destroy();
            message.success('WireGuard VPN 连接成功');
        } catch (error: any) {
            message.destroy();
            message.error(`连接失败: ${error.message || '未知错误'}`);
        }
    };

    const handleDisconnect = async () => {
        try {
            message.loading('正在断开连接...', 0);
            await disconnect();
            message.destroy();
            message.success('已断开 WireGuard VPN 连接');
        } catch (error: any) {
            message.destroy();
            message.error(`断开连接失败: ${error.message || '未知错误'}`);
        }
    };

    const btnstyles = "btn group w-full bg-gradient-to-t from-indigo-600 to-indigo-500 bg-[length:100%_100%] bg-[bottom] text-white shadow-[inset_0px_1px_0px_0px_theme(colors.white/.16)] hover:from-indigo-700 hover:to-indigo-400"

    return (
        <div>
            <p style={{ color: 'white', fontSize: '12px' }}>平台1: {platform} | 状态1: {status.status}</p>
            {status.status==='connected' ? (
                <Button
                    type="text"
                    onClick={handleDisconnect}
                    style={{ color: 'white', height: '44px' }}
                    className={btnstyles + ' mt-12 w-full'}
                >
                    Disconnect WireGuard
                </Button>
            ) : (
                <Button
                    type="text"
                    onClick={handleConnect}
                    style={{ color: 'white', height: '44px' }}
                    className={btnstyles + ' mt-12 w-full'}
                >
                    Test WireGuard
                </Button>
            )}
            <PluginDebug />
        </div>
    );
}


