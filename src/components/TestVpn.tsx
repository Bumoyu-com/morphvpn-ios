import { Button, message } from 'antd';
import { Capacitor } from '@capacitor/core';
import { useWireGuard } from '../hooks/useWireGuard';
import { PluginDebug } from './PluginDebug';

export function VPNComponent() {
    // WireGuard 配置 - 请替换为你的实际配置
    const myConfig = `[[Interface]
PrivateKey = CNn6mRkPAAOujl0kSdm/YJmZXHNymyGFcl38j9L8G1U=
Address = 10.8.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = AtTmwsbPKiOJuQVyI+uqXLqGNiBER2PMtQTBk7hQ0mg=
PresharedKey = DsfyIG7P6k4Q4yR9e8xp8dKuQAJaRF38hK0yzUQMrnI=
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 0
Endpoint = 154.8.229.164:51820
`;

    const { status, isConnected, connect, disconnect } = useWireGuard();
    const platform = Capacitor.getPlatform();

    const handleConnect = async () => {
        try {
            console.log('🔵 VPNComponent: handleConnect called');
            console.log('🔵 Platform:', platform);
            console.log('🔵 Config length:', myConfig.length);
            console.log('🔵 Config first 100 chars:', myConfig.substring(0, 100));
            console.log('🔵 Config starts with:', myConfig.substring(0, 20));
            
            // 验证配置格式
            if (!myConfig.includes('[Interface]')) {
                console.error('❌ Config missing [Interface] section');
                message.error('配置格式错误：缺少 [Interface] 部分');
                return;
            }
            if (!myConfig.includes('[Peer]')) {
                console.error('❌ Config missing [Peer] section');
                message.error('配置格式错误：缺少 [Peer] 部分');
                return;
            }
            
            message.info(`当前平台: ${platform}`, 2);
            
            if (platform === 'web') {
                message.warning('WireGuard 不支持 Web 平台，请在 iOS 设备上测试', 3);
                return;
            }
            
            message.loading('正在连接 WireGuard VPN...', 0);
            console.log('🔵 Calling connect with config...');
            await connect(myConfig, 'MorphVPN');
            console.log('✅ Connect succeeded');
            message.destroy();
            message.success('WireGuard VPN 连接成功');
        } catch (error: any) {
            console.error('❌ Connect failed:', error);
            console.error('❌ Error details:', JSON.stringify(error));
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


