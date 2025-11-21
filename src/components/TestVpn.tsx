import { Button, message } from 'antd';
import { useWireGuard } from '../hooks/useWireGuard';

export function VPNComponent() {
    const myConfig = `[Interface]
PrivateKey = 4FAuk91EWMmYbHOJKPT0GVHopvhGpOyXWJk5/go701c=
Address = 10.8.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = ldJcapNtklnbdrrosd8MtineLSXH8wGj5b0y+vLY2AQ=
PresharedKey = DgQRTsw743qlUJcWPcB5TgSdNfMimKXBVkolLOITg1A=
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 0
Endpoint = 65.20.89.15:51820`;

    const { status, isConnected, connect, disconnect } = useWireGuard();

    const handleConnect = async () => {
        try {
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
            <p>Status: {status.status}</p>
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
        </div>
    );
}


