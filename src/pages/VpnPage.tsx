import React, { useEffect, useState } from 'react';
import { useStore } from 'react-redux'
import { useNavigate } from 'react-router-dom';
import { message } from 'antd';
import { useTranslation } from 'react-i18next';

import { useGlobalStore } from '../store/module';
import { serverCheck, updateInvoke } from '../components/BaseRequest';
import { createConfigId, createConfig, pingGoo, pingGoo2 } from '../components/MyRequest';

import Vpngroup from '../components/NewVpnGroup';
import VpnModal from '../components/VpnModal';
import VpnDrawer from '../components/settingGroup/main';
import { getData, setData, showMessageBox, showNotification } from '../components/MyStorage';
import { getTraffic } from '../components/BaseRequest';

interface LoginPageProps { }
interface StoreState {
    global: any;
}
const VpnPage: React.FC<LoginPageProps> = ({ }) => {
    const store = useStore<StoreState>();
    const { allState, userInfo, setUserInfo } = useGlobalStore();
    const [vpnFullName, setVpnFullName] = useState('');
    const [creating, setCreating] = useState(false);
    const [connecting, setConnecting] = useState(false);
    const [creatingTime, setCreatingTime] = useState<number>(0);
    const { i18n } = useTranslation();

    const navigate = useNavigate();

    //点击连接触发请求
    const onVpnConnect = async () => {
        //按钮转圈显示连接中
        setConnecting(true)
        if (userInfo.vpnConnect) {
            vpnConnector(false);
        }
        else {
            let flag = await checkTraffic(userInfo);
            if (flag === 'empty') {
                setConnecting(false);
                showMessageBox(i18n.t('vpn.empty-title'), i18n.t('vpn.balance-empty'));
                return
            }
            else {
                if (userInfo.id) {
                    setCreating(true);
                    let serverInfo = await createServer();
                    console.log('服务器信息', serverInfo);
                    setCreatingTime(0);
                    if (!serverInfo) {
                        console.error('创建服务器失败');
                        setCreating(false);
                        setConnecting(false);
                        return
                    }
                    let config = await vpnConfig(serverInfo);
                    console.log('wireguard配置', config);
                    setCreating(false);

                    if (config) {
                        vpnConnector(true, config, serverInfo);
                    }
                    else {
                        setConnecting(false);
                        message.error(i18n.t('vpn.configuration-failed'));
                    }
                }
                else {
                    setConnecting(false);
                    message.error(i18n.t('account.login-first'));
                }
            }
        }
    }
    //申请或者查看服务器
    const createServer = async () => {
        let serverInfo = null;
        let flag = false, count = 0, percent = 0;

        while (!flag && count < 99) {
            let res = await serverCheck(userInfo.vpnChoose);
            if (res.data?.msg === 'success') {
                serverInfo = res.data;
                flag = true;
                break;
            }
            else {
                if (res.error) {
                    console.log('启动请求报错==>>', res.error);
                }
                else {
                    console.log('轮询booting==>>', count, res.data?.msg, res.data);
                    if (res.data?.msg === 'server in creating') {
                        let random = (Math.floor(Math.random() * 10)) % 4 + 6;
                        if (percent + random > 99) percent = 99
                        else percent += random;
                        setCreatingTime(percent);
                    }
                }
            }
            await new Promise(resolve => setTimeout(resolve, 10000));
            count++;
        }
        return serverInfo ? serverInfo.server : null
    }
    //处理vpnConfig加载或创建配置
    const vpnConfig = async (serverInfo: any) => {
        console.log('创建新配置,当前网络: GFW is', window.gfw);
        let newData = await createConfigId(serverInfo.ip, userInfo.id);
        console.log('新配置id', newData.data);
        if (!newData.data) {
            console.log('创建配置id失败');
            message.error(i18n.t('vpn.creating-config-failed'));
            return null
        }

        let config = await createConfig(serverInfo.ip, newData.data);
        if (config.data && typeof config.data === 'string') {
            return config.data
        }
        else {
            console.log(config);
            message.error(i18n.t('vpn.creating-config-failed'));
            return null
        }
    }

    //检测wireguard状态
    const checkVpnConnect = async (targetIP: string, serverName: string) => {
        var pass = false
        var times = 0
        var failtimes = 0
        while (!pass && times < 8) {
            times++
            let pintRes
            await new Promise(resolve => setTimeout(resolve, 5000));
            try {
                if (failtimes < 4) {
                    pintRes = await pingGoo(targetIP).catch(() => failtimes += 1);
                }
                else {
                    pintRes = await pingGoo2(targetIP).catch(() => failtimes += 1);
                }
                console.log('failtimes', pintRes);
            }
            catch (err) {
                console.log(err);
                pintRes = 'ping error';
            }
            if (pintRes === 'success') pass = true
        }

        if (pass) {
            message.success(i18n.t('vpn.connect-success'), 1.5);
            setUserInfo({ ...userInfo, vpnConnect: true });
            setVpnFullName(serverName);
        }
        else {
            message.error(i18n.t('vpn.connect-failed'), 5);
            await window.morphVpn.disconnect();
            setUserInfo({ ...userInfo, vpnConnect: false });
            setConnecting(false);
            console.log('vpn已关闭');
        }
    }
    //vpn开关
    const vpnConnector = async (bool: boolean, configStr?: string, serverInfo?: any) => {
        try {
            if (!window.morphVpn) {
                console.error('morphVpn未安装');
                setUserInfo({ ...userInfo, vpnConnect: false });
                setConnecting(false);
            }
            else {
                if (bool) {
                    if (configStr && serverInfo) {
                        let serverStr = `${serverInfo.ip}:${serverInfo.udpPort}:${userInfo.id}`
                        await window.morphVpn.connect(configStr, serverStr, serverInfo.info);
                        console.log('vpn已打开,检测IP', serverInfo);
                        await checkVpnConnect(serverInfo.ip, serverInfo.name);
                    }
                    else {
                        console.error('缺少配置信息');
                        setUserInfo({ ...userInfo, vpnConnect: false });
                    }
                }
                else {
                    await window.morphVpn.disconnect();
                    let userInfo = store.getState().global?.userInfo;
                    console.log('关闭vpn', userInfo);
                    setUserInfo({ ...userInfo, vpnConnect: false });
                    console.log('vpn已关闭');
                }
            }
            setConnecting(false);
        }
        catch (err) {
            console.log('开启vpn失败', err);
        }

    }
    //没有保存过密码会缓存
    const saveData = async () => {
        try {
            await getData();
        }
        catch (err: any) {
            console.log('saveData', err);
            if (!err.message.includes('Cannot read properties of undefined')) {
                await setData(allState);
            }
        }

        console.log('当前用户数据', allState);
    }

    const checkTraffic = async (userInfo: any) => {
        if (!userInfo.id) {
            console.log('getTraffic loop==>> 用户信息不存在');
            return '';
        }
        let info = await getTraffic(userInfo.id);
        let traffic = info?.data[0]?.traffic;
        if (!traffic && traffic !== 0) {
            console.log('getTraffic loop==>> 流量信息不存在');
            return '';
        }
        console.log('getTraffic loop Traffic is ', traffic);
        setUserInfo({ ...userInfo, balance: traffic });

        if (traffic < 1) {
            return 'empty';
        }
        else if (traffic < (1024 * 1024 * 1024)) {
            return 'low';
        }
        else if (traffic >= (1024 * 1024 * 1024)) {
            window.showNotification = true;
            return 'normal';
        }
        else return 'normal';
    };

    //登录检测
    useEffect(() => {
        // showNotification('MorphVPN', 'Welcome to MorphVPN');
        if (!userInfo.email) {
            navigate('/');
            message.error(i18n.t('account.login-first'));
        }
        else {
            saveData();
            if (!window.globalInterval) {
                console.log('开始全局轮询');

                window.globalInterval = setInterval(async () => {
                    let userInfo = store.getState().global?.userInfo;
                    let flag = await checkTraffic(userInfo);
                    if (flag === 'empty') {
                        if (userInfo.vpnConnect) {
                            vpnConnector(false);
                            console.log('流量为空,关闭vpn');
                            setTimeout(async () => {
                                await showMessageBox(i18n.t('vpn.empty-title'), i18n.t('vpn.balance-empty'));
                            }, 2000);
                        }

                        if (window.showNotification) {
                            await showNotification(i18n.t('vpn.low-title'), i18n.t('vpn.balance-warning'));
                            window.showNotification = false;
                        }
                    }
                    else if (flag === 'low') {
                        if (window.showNotification) {
                            await showNotification(i18n.t('vpn.low-title'), i18n.t('vpn.balance-warning'));
                            window.showNotification = false;
                        }
                    }
                }, 600000)
            }

            const payInfo = JSON.parse(localStorage.getItem('payInfo') || '{}');
            if (payInfo.success) {
                console.log('支付成功', payInfo);
                message.success(i18n.t('account.login-first'));
                localStorage.removeItem('payInfo');
            }
        }

        return () => {
            console.log('清除全局轮询');
            clearInterval(window.globalInterval)
            window.globalInterval = null
        }
    }, [])

    //连接中轮询
    useEffect(() => {
        if (userInfo.vpnConnect && vpnFullName) {
            if (!window.keepConnect) {
                console.log('30分钟后开始Invoke轮询');

                window.keepConnect = setInterval(() => {
                    console.log('Invoke轮询名字是=> ', vpnFullName);
                    updateInvoke(vpnFullName);
                }, 1800000)
            }
        }
        else {
            // console.log('清除Invoke轮询');
            clearInterval(window.keepConnect)
            window.keepConnect = null
        }

        return () => {
            console.log('清除Invoke轮询');
            clearInterval(window.keepConnect)
            window.keepConnect = null
        }
    }, [vpnFullName, userInfo.vpnConnect]);

    return (
        <div className="flex items-center justify-center h-screen w-screen p-3">
            <div id='vpnOuter' className="rounded-lg h-full w-full max-w-md dark:bg-gray-900 p-2">

                {userInfo.email ?
                    <div className="w-full h-full sm:px-6 sm:pt-1 p-2 pt-6 mx-auto max-w-md select-none">

                        <div className='mb-4 grid grid-cols-2'>
                            <VpnModal />
                            <VpnDrawer />
                        </div>
                        <Vpngroup onSubmit={onVpnConnect} connecting={connecting} creating={creating} creatingTime={creatingTime} />
                    </div>
                    : <></>}

            </div>
        </div>
    );
}

export default VpnPage;
