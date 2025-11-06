interface Window {
    getStore: () => void;
    changeLang: () => void;
    morphVpn: any;
    serverAddr: string;
    keepConnect: Timer | undefined | null;
    globalInterval: Timer | undefined | null;
    debounce: any;
    gfw: boolean;
    Neutralino: any;
    capStorage: any;
    showNotification: boolean;
    LocalNotifications: any;
    Dialog: any;
    baseApi: string;
}