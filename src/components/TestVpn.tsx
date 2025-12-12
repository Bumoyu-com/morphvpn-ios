import { Button, message } from 'antd';
import { Capacitor } from '@capacitor/core';
import { useWireGuard } from '../hooks/useWireGuard';
import { PluginDebug } from './PluginDebug';

export function VPNComponent() {
    // WireGuard 配置 - 请替换为你的实际配置
    const myConfig = `[Interface]
PrivateKey = 0DiA6lqJWUcqouJeuh17wNaJB9bIyNuj+pH2zVgoJWk=
Address = 10.8.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = 4oFUG+Nl2hIQx0b3j1IM203+vc0ygkz3IqwtboJoki4=
PresharedKey = jwvV/AuQpnk0QT5xeDGS143NqNP275zw2yvY0moVsE0=
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 0
Endpoint = 81.70.251.128:51820
`;

    const { status, isConnected, connect, disconnect } = useWireGuard();
    const platform = Capacitor.getPlatform();

    const handleConnect = async () => {
        try {
            // 连接配置
            const connectOptions = {
                config: myConfig,
                tunnelName: 'MorphVPN',
                // 启用 MorphProtocol
                useMorphProtocol: true,
                morphEncryptionKey: 'XuNgTBIiWFXHSeunT/xPi6DEp98vjw6XBoGogtIJbE8=:4jww75fhLvms4akS',
                morphServerHost: 'morph.example.com',
                morphServerPort: 51821,
                morphLayerCount: 3,
                morphPaddingLength: 8
            };

            message.info(`当前平台: ${platform}`, 2);

            if (platform === 'web') {
                message.warning('WireGuard 不支持 Web 平台，请在 iOS 设备上测试', 3);
                return;
            }

            message.loading('正在连接 WireGuard VPN...', 0);
            console.log('🔵 Calling connect with config...');
            await connect(connectOptions.config, connectOptions.tunnelName);
            message.destroy();
            message.success('VPN 连接成功（已启用流量混淆）');
        } catch (error: any) {
            console.error('❌ Connect failed:', error);
            message.error(`连接失败: ${error.message}`);
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
            <p style={{ color: 'white', fontSize: '12px' }}>平台1: {platform} | 状态: {status.status}</p>
            {isConnected ? (
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


