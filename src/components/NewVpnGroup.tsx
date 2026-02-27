import React, { useState, useEffect } from 'react'
import { useTranslation } from 'react-i18next';
import { Button, message } from 'antd';
import axios from 'axios';

import { useGlobalStore } from '../store/module';
import { listCity, getTraffic } from './BaseRequest';
import { vpnListType, extractVpnList } from './vpnList'
import { setData } from './MyStorage';

interface VpnNodeStatus {
    ping: number | null;
    speed: number | null;
    pingTesting: boolean;
    speedTesting: boolean;
}

interface NewVpnGroupProps {
    onSubmit: () => void;
    connecting: boolean;
    creating: boolean;
    creatingTime: number;
    onTestAllReady?: (testAllFn: () => void) => void;
    onTestAllSpeedReady?: (testAllSpeedFn: () => void) => void;
    stopCreating?: () => void;
}

const NewVpnGroup: React.FC<NewVpnGroupProps> = ({ onSubmit, connecting, creating, creatingTime, onTestAllReady, onTestAllSpeedReady, stopCreating }) => {
    const { allState, userInfo, setUserInfo } = useGlobalStore();
    const [selected, setSelected] = useState<string>('');
    const [vpnList, setVpnList] = useState<vpnListType[]>([]);
    const [nodeStatus, setNodeStatus] = useState<Record<string, VpnNodeStatus>>({});
    const [loading, setLoading] = useState<boolean>(true);

    const { i18n } = useTranslation();

    //选择vpn
    const handleRadioSet = async (e: vpnListType) => {
        if (!connecting) {
            console.log(e);
            setSelected(e.code);
            let newInfo = { ...userInfo, vpnChoose: e.code };
            setUserInfo(newInfo);
            await setData({ ...allState, userInfo: newInfo });
        }

    }

    //调用连接vpn
    const connectVpn = async () => {
        if (connecting) return
        if (userInfo.vpnChoose) {
            onSubmit();
        }
        else message.error(i18n.t('vpn.no-selected'));
    }
    //渲染vpn列表
    const renderVpnList = async () => {
        setLoading(true);
        let info = await getTraffic(userInfo.id);
        console.log('user admin==>>', info?.data[0]?.status === 'admin');
        const { data, error } = await listCity(99, 0);
        if (data) {
            console.log(data);
            const list = extractVpnList(data, info?.data[0]?.status === 'admin');
            setVpnList(list);
            setLoading(false);

            // 首次加载完成后进行全体测速
            setTimeout(() => {
                testAllPing(list);
            }, 500);
        }
        else {
            console.log(error);
            message.error(i18n.t('vpn.network-error'));
            setLoading(false);
        }
    }

    // 测试所有节点的下载速度
    const testAllSpeed = async (list: vpnListType[]) => {
        console.log('开始全体测下载速度...');
        for (const node of list) {
            if (node.testUrl) {
                await testSpeedInternal(node.code, list);
                // 添加小延迟避免请求过快
                await new Promise(resolve => setTimeout(resolve, 200));
            }
        }
    };

    // 测试所有节点的ping
    const testAllPing = async (list: vpnListType[]) => {
        console.log('开始全体测速...');
        for (const node of list) {
            if (node.testIp) {
                setNodeStatus(prev => ({
                    ...prev,
                    [node.code]: { ...prev[node.code], pingTesting: false, ping: null }
                }));
            }
        }
        let cache = []
        for (let i = 0; i < list.length; i++) {
            if (list[i].testIp) {
                cache.push({ ip: list[i].testIp, nodeCode: list[i].code })
                if (cache.length === 4) {
                    testPingMultiple(cache);
                    await new Promise(resolve => setTimeout(resolve, 1000));
                    cache = [];
                }
            }
        }
    };

    // 测试ping延迟（带事件参数，用于UI点击）
    const testPing = async (e: React.MouseEvent, nodeCode: string) => {
        e.stopPropagation();
        const node = vpnList.find(n => n.code === nodeCode);
        if (!node || !node.testIp) {
            return;
        }

        setNodeStatus(prev => ({
            ...prev,
            [nodeCode]: { ...prev[nodeCode], pingTesting: true, ping: null }
        }));

        try {
            let ping = await window.PingBridge.ping(node.testIp)
            setNodeStatus(prev => ({
                ...prev,
                [nodeCode]: { ...prev[nodeCode], pingTesting: false, ping: ping - 1 }
            }));
        } catch (error) {
            console.log(error);
            setNodeStatus(prev => ({
                ...prev,
                [nodeCode]: { ...prev[nodeCode], pingTesting: false, ping: -1 }
            }));
        }
    };

    const testPingMultiple = async (targetList: { ip: string; nodeCode: string }[]) => {
        try {
            const result = await window.PingBridge.pingConcurrent(targetList.map(item => item.ip));
            for (const r of result) {
                const code = targetList.find(n => n.ip === r.ip);
                if (!code) continue;
                setNodeStatus(prev => ({
                    ...prev,
                    [code.nodeCode]: { ...prev[code.nodeCode], pingTesting: false, ping: r.avgRtt - 1 }
                }));
            }
        } catch (error) {
            /* 异常分支同理 */
            for (const t of targetList) {
                const code = targetList.find(n => n.ip === t.ip);
                if (!code) continue;
                setNodeStatus(prev => ({
                    ...prev,
                    [code.nodeCode]: { ...prev[code.nodeCode], pingTesting: false, ping: -1 }
                }));
            }
        }
    };

    // 测试下载速度（带事件参数，用于UI点击）
    const testSpeed = async (e: React.MouseEvent, nodeCode: string) => {
        e.stopPropagation();
        await testSpeedInternal(nodeCode, vpnList);
    };

    // 内部速度测试函数（不需要事件参数）
    const testSpeedInternal = async (nodeCode: string, list: vpnListType[]) => {
        const node = list.find(n => n.code === nodeCode);
        if (!node || !node.testUrl) {
            return;
        }

        setNodeStatus(prev => ({
            ...prev,
            [nodeCode]: { ...prev[nodeCode], speedTesting: true, speed: null }
        }));

        const testUrl = `${node.testUrl}vultr.com.100MB.bin`;
        const startTime = Date.now(); // 总体开始时间
        let downloadStartTime = null; // 实际下载开始时间（达到100KB后记录）
        let downloadedBytes = 0;
        let hasExceededThreshold = false; // 是否已超过100KB阈值
        let overallTimeoutId;
        try {
            const controller = new AbortController();

            // 设置总超时（10秒）
            overallTimeoutId = setTimeout(() => {
                controller.abort();
            }, 7000);

            const response = await axios.get(testUrl, {
                signal: controller.signal,
                responseType: 'blob',
                onDownloadProgress: (progressEvent) => {
                    downloadedBytes = progressEvent.loaded;

                    // 如果还未开始计时，且下载量超过100KB
                    if (!hasExceededThreshold && downloadedBytes > 100 * 1024) {
                        hasExceededThreshold = true;
                        downloadStartTime = Date.now(); // 记录实际下载开始时间
                        // console.log(`实际下载开始，已下载 ${(downloadedBytes / 1024).toFixed(2)} KB`);
                    }
                }
            });

            // 请求成功完成，清理总超时计时器
            clearTimeout(overallTimeoutId);

            let finalDuration;
            let sizeMB = downloadedBytes / (1024 * 1024);

            if (hasExceededThreshold && downloadStartTime) {
                // 如果达到了阈值：使用实际下载时间计算速度
                finalDuration = (Date.now() - downloadStartTime) / 1000;

            } else {
                // 如果未达到阈值（例如文件太小）：使用整个过程的耗时
                finalDuration = (Date.now() - startTime) / 1000;
                console.warn('下载量未达到100KB阈值，使用整体耗时计算速度');
            }
            console.log('实际下载时间', finalDuration, '实际下载量', `${sizeMB}MB`);
            const speedMbps = (sizeMB * 8) / finalDuration;

            setNodeStatus(prev => ({
                ...prev,
                [nodeCode]: { ...prev[nodeCode], speedTesting: false, speed: speedMbps }
            }));

            console.log(`${i18n.t('vpn.speed') || 'Speed'}: ${speedMbps.toFixed(2)} Mbps`);

        } catch (error: any) {
            clearTimeout(overallTimeoutId); // 清理超时计时器

            let finalDuration;
            let sizeMB = downloadedBytes / (1024 * 1024);

            // 计算耗时：区分是否达到了阈值
            if (hasExceededThreshold && downloadStartTime) {
                finalDuration = (Date.now() - downloadStartTime) / 1000;
            } else if (downloadedBytes > 0) {
                // 有下载数据但未达到阈值，使用整体时间
                finalDuration = (Date.now() - startTime) / 1000;
            } else {
                // 没有任何数据下载成功
                finalDuration = 0;
            }

            console.log('使用实际下载时间计算速度', finalDuration);
            // 如果是超时中断或其它错误
            if ((error.code === 'ERR_CANCELED' && downloadedBytes > 0) || hasExceededThreshold) {
                const speedMbps = sizeMB > 0 && finalDuration > 0 ? (sizeMB * 8) / finalDuration : 0;

                setNodeStatus(prev => ({
                    ...prev,
                    [nodeCode]: { ...prev[nodeCode], speedTesting: false, speed: speedMbps }
                }));
                const statusText = speedMbps > 0 ?
                    `${i18n.t('vpn.speed') || 'Speed'}: ${speedMbps.toFixed(2)} Mbps` :
                    'Speed test completed with limited data';
                console.log(statusText);
            } else {
                console.error('Speed test failed:', error);
                setNodeStatus(prev => ({
                    ...prev,
                    [nodeCode]: { ...prev[nodeCode], speedTesting: false, speed: -1 }
                }));
                message.error(i18n.t('vpn.speed-test-failed') || 'Speed test failed');
            }
        }
    };

    // 初始化加载节点列表
    useEffect(() => {
        renderVpnList();
        if (userInfo.vpnChoose) {
            setSelected(userInfo.vpnChoose);
        }
    }, []) // 只在组件挂载时执行一次

    // 当vpnList更新时，传递testAllPing和testAllSpeed函数给父组件
    useEffect(() => {
        if (vpnList.length > 0) {
            if (onTestAllReady) {
                onTestAllReady(() => testAllPing(vpnList));
            }
            if (onTestAllSpeedReady) {
                onTestAllSpeedReady(() => testAllSpeed(vpnList));
            }
        }
    }, [vpnList.length]) // 只依赖列表长度，避免无限循环

    const btnstyles = "btn group w-full bg-gradient-to-t from-indigo-600 to-indigo-500 bg-[length:100%_100%] bg-[bottom] text-white shadow-[inset_0px_1px_0px_0px_theme(colors.white/.16)] hover:from-indigo-700 hover:to-indigo-400"
    // const btnstyles = "btn-sm                bg-gradient-to-t from-indigo-600 to-indigo-500 bg-[length:100%_100%] bg-[bottom] text-white shadow-[inset_0px_1px_0px_0px_theme(colors.white/.16)] hover:bg-[length:100%_150%] py-[5px] "
    // const anime = " hover:from-indigo-500 hover:to-purple-700 active:from-indigo-700 active:to-purple-800"

    return (
        <>
            <div className='overflow-y-auto max-h-[calc(100vh-280px)] sm:max-h-[calc(100vh-300px)] vpn-list-scroll'>
                {loading ? (
                    <div className="flex flex-col gap-2 sm:gap-3">
                        {[1, 2, 3, 4, 5, 6, 7].map((i) => (
                            <div key={i} className="w-full rounded-lg px-3 sm:px-4 py-3 sm:py-4 bg-gray-900 border border-gray-700 animate-pulse">
                                <div className="flex items-center gap-2 sm:gap-3">
                                    <div className="w-8 h-8 sm:w-10 sm:h-10 rounded-full bg-gray-800"></div>
                                    <div className="flex-1">
                                        <div className="h-4 bg-gray-800 rounded w-24 mb-2"></div>
                                        <div className="h-3 bg-gray-800 rounded w-32"></div>
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                ) : (
                    <div className="flex flex-col gap-2 sm:gap-3">
                        {vpnList.map((ele: vpnListType, ind) => {
                            const status = nodeStatus[ele.code] || { ping: null, speed: null, pingTesting: false, speedTesting: false };
                            return (
                                <div
                                    key={ele.code}
                                    className={
                                        `${selected === ele.code ? 'bg-gradient-to-r from-indigo-600 to-indigo-500 text-white border-indigo-400 vpn-node-selected shadow-lg shadow-indigo-500/50' : 'bg-gray-900 hover:bg-gray-800 hover:border-gray-600 border-gray-700 hover:shadow-lg'} 
                                    w-full relative cursor-pointer rounded-lg px-3 sm:px-4 py-3 sm:py-4 shadow-md border transition-all duration-400 
                                    focus:outline-none text-slate-200 vpn-node-enter hover:scale-[1] active:scale-[0.94]`
                                    }
                                    onClick={() => handleRadioSet(ele)}
                                >
                                    <div className="flex items-center justify-between gap-2">
                                        <div className="flex items-center gap-2 sm:gap-3 flex-1 min-w-0">
                                            {/* <div className={`w-8 h-8 sm:w-10 sm:h-10 rounded-full flex items-center justify-center text-lg sm:text-xl flex-shrink-0 ${selected === ele.code ? 'bg-white/20' : 'bg-gray-800'}`}>
                                                🌐
                                            </div> */}
                                            <div className="flex flex-col flex-1 min-w-0">
                                                <div className="font-medium text-sm sm:text-base truncate">{i18n.t(`city.${ele.code}`)}</div>
                                                <div className={`text-xs sm:text-sm truncate ${selected === ele.code ? 'text-white/80' : 'text-gray-400'}`}>
                                                    {ele.country}
                                                </div>
                                            </div>
                                        </div>
                                        <div className="flex items-center gap-1 sm:gap-2 flex-shrink-0">
                                            <button
                                                onClick={(e) => testPing(e, ele.code)}
                                                disabled={status.pingTesting || connecting}
                                                className={`test-button px-2 py-1 rounded-md text-xs sm:text-sm font-medium transition-all duration-200 ${status.pingTesting
                                                    ? 'bg-gray-700 text-gray-300 cursor-wait'
                                                    : status.ping === null
                                                        ? selected === ele.code ? 'bg-white/20 hover:bg-white/30 text-white' : 'bg-gray-800 hover:bg-gray-700 text-gray-300'
                                                        : status.ping === -1
                                                            ? 'bg-red-900/50 text-red-300 hover:bg-red-900/70'
                                                            : status.ping <= 600
                                                                ? 'bg-green-900/50 text-green-300 hover:bg-green-900/70'
                                                                : 'bg-yellow-900/50 text-yellow-300 hover:bg-yellow-900/70'
                                                    } disabled:opacity-50 disabled:cursor-not-allowed`}
                                                title="Test Ping"
                                            >
                                                {status.pingTesting
                                                    ? i18n.t('vpn.ping-testing')
                                                    : status.ping === null
                                                        ? '--'
                                                        : status.ping === -1
                                                            ? i18n.t('vpn.ping-timeout')
                                                            : `${status.ping}ms`
                                                }
                                            </button>
                                            <button
                                                onClick={(e) => testSpeed(e, ele.code)}
                                                disabled={status.speedTesting || connecting}
                                                className={`test-button px-2 py-1 rounded-md text-xs sm:text-sm font-medium transition-all duration-200 ${status.speedTesting
                                                    ? 'bg-gray-700 text-gray-300 cursor-wait'
                                                    : status.speed === null
                                                        ? selected === ele.code ? 'bg-white/20 hover:bg-white/30 text-white' : 'bg-gray-800 hover:bg-gray-700 text-gray-300'
                                                        : status.speed === -1
                                                            ? 'bg-red-900/50 text-red-300 hover:bg-red-900/70'
                                                            : status.speed <= 10
                                                                ? 'bg-red-900/50 text-red-300 hover:bg-red-900/70'
                                                                : status.speed <= 30
                                                                    ? 'bg-yellow-900/50 text-yellow-300 hover:bg-yellow-900/70'
                                                                    : 'bg-green-900/50 text-green-300 hover:bg-green-900/70'
                                                    } disabled:opacity-50 disabled:cursor-not-allowed`}
                                                title="Test Speed"
                                            >
                                                {status.speedTesting
                                                    ? i18n.t('vpn.speed-testing') || 'Testing'
                                                    : status.speed === null
                                                        ? '--'
                                                        : status.speed === -1
                                                            ? i18n.t('vpn.speed-timeout') || 'Timeout'
                                                            : status.speed
                                                                ? `${Math.round(status.speed)}M`
                                                                : <svg className="w-3 h-3 sm:w-4 sm:h-4 transition-transform group-hover:translate-x-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                                                                </svg>
                                                }
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                )}
            </div>

            <Button
                type="text"
                onClick={connectVpn}
                loading={connecting}
                style={{ color: 'white', height: '44px' }}
                className={btnstyles + ' mt-6 sm:mt-8 w-full transform transition-all duration-200 hover:scale-[1.02] active:scale-[0.98] hover:shadow-lg hover:shadow-indigo-500/50'}
            >
                {!userInfo.vpnConnect ?
                    connecting ?
                        creating ? creatingTime > 0 ? i18n.t('vpn.creatingnew', { time: creatingTime }) as string : i18n.t('vpn.creating') as string : i18n.t('vpn.connecting') as string
                        : i18n.t('vpn.connect') as string
                    : i18n.t('vpn.disconnect') as string}
            </Button>

            {(creatingTime > 0 && creating) && <Button
                type="text"
                onClick={stopCreating}
                style={{ color: 'white', height: '44px' }}
                className={btnstyles + ' mt-6 sm:mt-8 w-full transform transition-all duration-200 hover:scale-[1.02] active:scale-[0.98] hover:shadow-lg hover:shadow-indigo-500/50'}
            >
                {i18n.t('vpn.stop')}
            </Button>
            }
        </>
    )
}

export default NewVpnGroup;
