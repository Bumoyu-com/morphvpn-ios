import { message } from 'antd';
export const setData = async (dataObj: object) => {
    if (window.Neutralino) {
        await window.Neutralino.storage.setData('userData', JSON.stringify(dataObj));
    }
    else if (window.capStorage) {
        await window.capStorage.set({
            key: 'userData',
            value: JSON.stringify(dataObj),
        });
    }
    else {
        localStorage.setItem('userData', JSON.stringify(dataObj));
    }
};


export const getData = async () => {
    if (window.Neutralino) {
        return await window.Neutralino.storage.getData('userData') as string;
    }
    else if (window.capStorage) {
        let res = await window.capStorage.get({ key: 'userData' })
        if (!res.value) {
            console.log('getdata cap error', res);
            return null;
        }
        return res.value as string;
    }
    else {
        return localStorage.getItem('userData');
    }
};

export const removeData = async () => {
    await window.capStorage.remove({ key: 'userData' });
};
export const checkStorage = async () => {
    if (window.Neutralino) {
        console.log('storage neutralino');
    }
    else if (window.capStorage) {
        console.log('storage cap');
    }
    else {
        console.log('storage web');
    }
};

export const showNotification = async (title: string, content: string) => {
    if (window.Neutralino) {
        await window.Neutralino.os.showNotification(title, content);
        console.log('showNotification neutralino');
    }
    else if (window.capStorage) {
        try {
            // 安排通知
            await window.LocalNotifications.schedule({
                notifications: [
                    {
                        title: title,
                        body: content,
                        id: 2147483638, // 唯一ID
                        schedule: { at: new Date(Date.now() + 1000) }, // 3秒后触发
                        sound: 'default', // 使用默认声音
                        extra: { data: '' }
                    }
                ]
            });
            console.log('showNotification cap');
        } 
        catch (error) {
            console.error('通知错误:', error);
        }
    }
    else {
        message.warning(content, 10);
        console.log('showNotification web');
    }
};
export const showMessageBox = async (title: string, content: string) => {
    if (window.Neutralino) {
        await window.Neutralino.os.showMessageBox(title, content, 'OK', 'INFO');
        console.log('showMessageBox neutralino');
    }
    else if (window.capStorage) {
        await window.Dialog.alert({
            title: title,
            message: content,
        });
        console.log('showMessageBox cap');
    }
    else {
        message.error(content, 10);
        console.log('showMessageBox web');
    }
};
