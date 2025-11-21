import { Button } from 'antd';
import { useWireGuard } from '../hooks/useWireGuard';

export function VPNComponent() {
    const myConfig = `
[Interface]
PrivateKey = YOUR_PRIVATE_KEY
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = vpn.example.com:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
`;

    const { status, isConnected, connect, disconnect } = useWireGuard();

    const handleConnect = async () => {
        await connect(myConfig, 'MyVPN');
    };
    const btnstyles = "btn group w-full bg-gradient-to-t from-indigo-600 to-indigo-500 bg-[length:100%_100%] bg-[bottom] text-white shadow-[inset_0px_1px_0px_0px_theme(colors.white/.16)] hover:from-indigo-700 hover:to-indigo-400"


    return (
        <div>
            <p>Status: {status.status}</p>
            {isConnected ? (
                <Button
                    type="text"
                    onClick={disconnect}
                    style={{ color: 'white', height: '44px' }}
                    className={btnstyles + ' mt-12 w-full'}
                >
                    Disconnect
                </Button>
            ) : (
                <Button
                    type="text"
                    onClick={handleConnect}
                    style={{ color: 'white', height: '44px' }}
                    className={btnstyles + ' mt-12 w-full'}
                >
                    Connect
                </Button>
            )}
        </div>
    );
}


