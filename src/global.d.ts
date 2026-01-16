interface Window {
    getStore: () => void;
    changeLang: () => void;
    morphVpn: {
        connect: (wgConfig: string, serverStr: string, serverInfo: any) => Promise<{ success: boolean; message?: string }>;
        disconnect: () => Promise<{ success: boolean; message?: string }>;
        getStatus: () => {
            connected: boolean;
            morphConnected: boolean;
            wgConnected: boolean;
            localPort?: number;
            sessionPort?: number;
        };
    };
    serverAddr: string;
    keepConnect: ReturnType<typeof setInterval> | undefined | null;
    globalInterval: ReturnType<typeof setInterval> | undefined | null;
    debounce: any;
    gfw: boolean;
    Neutralino: any;
    capStorage: any;
    showNotification: boolean;
    LocalNotifications: any;
    Dialog: any;
    baseApi: string;
    PingBridge: {
        ping: (address: string) => Promise<number | null>;
        pingMultiple: (addresses: string[]) => Promise<Array<{ address: string; latency: number | null }>>;
        pingConcurrent: (addresses: string[]) => Promise<Array<{ address: string; latency: number | null }>>;
    };
}