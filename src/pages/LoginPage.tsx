import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

import { Button, message } from 'antd';
import { useGlobalStore } from '../store/module';
import { passwordVerify } from '../components/BaseRequest';
import Input from '../components/base/Input';
import LocaleSelector from '../components/settingGroup/LocaleSelector'
import { getData } from '../components/MyStorage';


interface LoginPageProps { }
const LoginPage: React.FC<LoginPageProps> = ({ }) => {
    const { setUserInfo, userInfo, setLocale } = useGlobalStore();

    const [userEmail, setuserEmail] = useState<string>('');
    const [userPSW, setuserPSW] = useState<string>('');
    const [address, setAddress] = useState<string>('');
    const [onSubmiting, setOnSubmiting] = useState(false);


    const navigate = useNavigate();
    const { i18n } = useTranslation();

    //提交开始查询用户存在
    const onSubmit: any = (email?: string, psw?: string, vpnChoose?: string) => {
        if (!onSubmiting) {
            if (email && psw) {
                setOnSubmiting(true);
                message.info(i18n.t('account.logining'), 2);
                loginHook(email, psw, vpnChoose)
            }
            else {
                if (!userEmail || !userPSW) {
                    message.error(i18n.t('account.login-failed'))
                    return
                }
                setOnSubmiting(true);
                message.info(i18n.t('account.logining'), 2);
                loginHook(userEmail, userPSW)
            }
        }
    }

    //跳转其他页面
    const jumpToSignup = () => {
        if (!window.debounce) {
            window.debounce = setTimeout(() => {
                navigate('/signup');
                window.debounce = null
            }, 200);
        }
    }
    const forgetPsw = () => {
        if (!window.debounce) {
            window.debounce = setTimeout(() => {
                navigate('/restore');
                window.debounce = null
            }, 200);
        }
    }

    // 登录钩子
    const loginHook = async (email: string, password: string, vpnChoose?: string) => {
        const { data, error } = await passwordVerify(email, password);
        if (data && data.result) {
            setOnSubmiting(false);
            setUserInfo({ ...userInfo, email: email, password: password, id: data.userId, vpnChoose: vpnChoose });
            console.log('login success');
            message.success(i18n.t('account.login-success'), 1);
            navigate('/vpn')
        }
        else if (error) {
            console.log('loginHook==>> network err');
            setOnSubmiting(false);
            message.error(i18n.t('account.network'));
        }
        else {
            console.log('loginHook==>> login failed');
            setOnSubmiting(false);
            message.error(i18n.t('account.login-failed'));
        }
    };

    const getStorage = async () => {
        try {
            let allDataStr = await getData();
            if (!allDataStr) {
                console.log('缓存加载失败');
                return
            }
            let allData = JSON.parse(allDataStr);
            let userData = allData.userInfo;
            if (userData?.email) {
                console.log('login缓存已加载', allData);
                setuserPSW(userData.password);
                setuserEmail(userData.email);
                setLocale(allData.locale);
                onSubmit(userData.email, userData.password, userData.vpnChoose);
            }
            else {
                console.log('没有mail缓存', userData);
            }
        }
        catch (err: any) {
            console.log('没有缓存', err.message);
        }
    }

    // ========== Ping 测试功能 ==========
    
    // 快速测试常用服务器
    async function testQuickPing() {
        const testServers = [
            { name: 'Google DNS', address: '8.8.8.8' },
            { name: 'Cloudflare DNS', address: '1.1.1.1' },
            { name: 'Google', address: 'google.com' }
        ];

        console.log('🏓 快速测试开始...');
        message.loading('正在测试网络延迟...', 0);

        try {
            const startTime = Date.now();
            const results = await window.PingBridge.pingConcurrent(
                testServers.map(s => s.address)
            );
            const totalTime = Date.now() - startTime;

            message.destroy();

            let successCount = 0;
            results.forEach((result, index) => {
                const server = testServers[index];
                if (result.latency !== null) {
                    console.log(`✅ ${server.name} (${result.address}): ${result.latency} ms`);
                    successCount++;
                } else {
                    console.log(`❌ ${server.name} (${result.address}): 超时`);
                }
            });

            if (successCount > 0) {
                message.success(`测试完成！${successCount}/${testServers.length} 个服务器可达 (${totalTime}ms)`, 3);
            } else {
                message.error('所有服务器都无法访问，请检查网络连接', 3);
            }
        } catch (error: any) {
            message.destroy();
            message.error(`测试失败: ${error?.message || '未知错误'}`, 3);
            console.error('Ping 测试错误:', error);
        }
    }

    // 单个地址测试
    async function testSinglePing() {
        if (!address || address.trim() === '') {
            message.warning('请输入要测试的地址');
            return;
        }

        console.log(`🏓 开始 ping ${address}...`);
        message.loading(`正在 ping ${address}...`, 0);

        try {
            const startTime = Date.now();
            const latency = await window.PingBridge.ping(address);
            const totalTime = Date.now() - startTime;

            message.destroy();

            if (latency !== null) {
                message.success(`✅ ${address}: ${latency} ms (总耗时: ${totalTime}ms)`, 3);
                console.log(`✅ 成功！平均延迟: ${latency} ms, 总耗时: ${totalTime} ms`);
            } else {
                message.error(`❌ ${address}: 超时或失败`, 3);
                console.log(`❌ 超时或失败`);
            }
        } catch (error: any) {
            message.destroy();
            message.error(`❌ 错误: ${error?.message || '未知错误'}`, 3);
            console.error('Ping 错误:', error);
        }
    }

    // 批量测试
    async function testMultiplePing() {
        const addresses = ['8.8.8.8', '1.1.1.1', 'google.com', 'cloudflare.com'];

        console.log(`🏓 开始批量测试 ${addresses.length} 个地址...`);
        message.loading('批量测试中...', 0);

        try {
            const startTime = Date.now();
            const results = await window.PingBridge.pingMultiple(addresses);
            const totalTime = Date.now() - startTime;

            message.destroy();

            let successCount = 0;
            results.forEach(result => {
                if (result.latency !== null) {
                    console.log(`✅ ${result.address}: ${result.latency} ms`);
                    successCount++;
                } else {
                    console.log(`❌ ${result.address}: 超时`);
                }
            });

            message.info(`批量测试完成: ${successCount}/${addresses.length} 成功 (${totalTime}ms)`, 3);
        } catch (error: any) {
            message.destroy();
            message.error(`批量测试失败: ${error?.message || '未知错误'}`, 3);
            console.error('批量测试错误:', error);
        }
    }

    // 并发测试
    async function testConcurrentPing() {
        const addresses = ['8.8.8.8', '1.1.1.1', 'google.com', 'cloudflare.com', 'github.com'];

        console.log(`🏓 开始并发测试 ${addresses.length} 个地址...`);
        message.loading('并发测试中...', 0);

        try {
            const startTime = Date.now();
            const results = await window.PingBridge.pingConcurrent(addresses);
            const totalTime = Date.now() - startTime;

            message.destroy();

            let successCount = 0;
            const sortedResults = results
                .map(r => ({ ...r, latency: r.latency ?? 9999 }))
                .sort((a, b) => a.latency - b.latency);

            sortedResults.forEach(result => {
                if (result.latency !== 9999) {
                    console.log(`✅ ${result.address}: ${result.latency} ms`);
                    successCount++;
                } else {
                    console.log(`❌ ${result.address}: 超时`);
                }
            });

            message.success(`并发测试完成: ${successCount}/${addresses.length} 成功 (${totalTime}ms)`, 3);
        } catch (error: any) {
            message.destroy();
            message.error(`并发测试失败: ${error?.message || '未知错误'}`, 3);
            console.error('并发测试错误:', error);
        }
    }


    useEffect(() => {
        setTimeout(() => {
            getStorage();
            if (window.PingBridge) {
                console.log('✅ PingBridge 已加载');
            } else {
                console.error('❌ PingBridge 未加载');
            }
        }, 100);
    }, []);

    // const btnstyles = "font-medium w-full shadow text-center rounded-lg bg-gradient-to-tr from-indigo-500 to-purple-500 transition-colors duration-300"
    const btnstyles = "btn group w-full bg-gradient-to-t from-indigo-600 to-indigo-500 bg-[length:100%_100%] bg-[bottom] text-white shadow-[inset_0px_1px_0px_0px_theme(colors.white/.16)] hover:from-indigo-700 hover:to-indigo-400"
    // const anime = " hover:from-indigo-500 hover:to-purple-700 active:from-indigo-700 active:to-purple-800"
    return (
        <>
            <div className="h-screen fixed bottom-0 left-0 w-full flex justify-center items-end min-h-screen px-3">
                <div className="overflow-y-scroll w-120 flex flex-col h-full justify-between pb-3 dark:bg-gray-900">
                    <div className="border border-gray-700 rounded-lg p-4 mt-10 relative">
                        {/* {__ENV__==='development' && <p className="mt-0 ml-1 text-lg font-medium text-white">Dev</p>} */}
                        <p className={`mt-12 ml-1 text-xl font-medium text-white`}>{i18n.t('account.login')}</p>

                        <LocaleSelector simple={true} />

                        <Input
                            id='login-email'
                            type={'text'}
                            value={userEmail}
                            onChange={e => setuserEmail(e.target.value)}
                            className='form-input h-12 mt-10 w-full'
                            placeholder={i18n.t('account.email')}
                        />
                        <Input
                            id='login-psw'
                            type={'password'}
                            value={userPSW}
                            onChange={e => setuserPSW(e.target.value)}
                            className='form-input h-11 mt-5 w-full'
                            placeholder={i18n.t('account.password')}
                        />
                        <p className={`mr-1 mt-5 px-2 py-1 rounded-lg cursor-pointer hover:bg-gray-800 float-left text-white`} onClick={jumpToSignup}>{i18n.t('account.signup')}</p>
                        <p className={`mr-1 mt-5 px-2 py-1 rounded-lg cursor-pointer hover:bg-gray-800 float-right text-white`} onClick={forgetPsw}>{i18n.t('account.foget-password')}</p>

                        <Button
                            type="text"
                            onClick={onSubmit}
                            loading={onSubmiting}
                            style={{ color: 'white', height: '44px' }}
                            className={btnstyles + ' mt-12 mb-12 w-full'}
                        >
                            {onSubmiting ? i18n.t('account.logining') as string : i18n.t('account.ok') as string}
                        </Button>

                        {/* Ping 测试区域 */}
                        <div className="border-t border-gray-700 pt-6 mt-6">
                            <p className="text-lg font-medium text-white mb-4">🏓 网络延迟测试</p>
                            
                            {/* 快速测试按钮 */}
                            <Button
                                type="text"
                                onClick={testQuickPing}
                                style={{ color: 'white', height: '44px' }}
                                className={btnstyles + ' mb-4 w-full'}
                            >
                                快速测试 (推荐)
                            </Button>

                            {/* 自定义地址测试 */}
                            <Input
                                id='singleAddress'
                                type={'text'}
                                value={address}
                                onChange={e => setAddress(e.target.value)}
                                className='form-input h-12 mb-3 w-full'
                                placeholder="输入地址测试 (如: 8.8.8.8)"
                            />
                            <Button
                                type="text"
                                onClick={testSinglePing}
                                style={{ color: 'white', height: '40px' }}
                                className={btnstyles + ' mb-3 w-full'}
                            >
                                测试此地址
                            </Button>

                            {/* 高级测试按钮 */}
                            <div className="grid grid-cols-2 gap-3 mt-4">
                                <Button
                                    type="text"
                                    onClick={testMultiplePing}
                                    style={{ color: 'white', height: '40px' }}
                                    className={btnstyles}
                                >
                                    批量测试
                                </Button>
                                <Button
                                    type="text"
                                    onClick={testConcurrentPing}
                                    style={{ color: 'white', height: '40px' }}
                                    className={btnstyles}
                                >
                                    并发测试
                                </Button>
                            </div>
                        </div>

                    </div>
                </div>

            </div>
        </>
    );
}

export default LoginPage;
