import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

import { Button, message } from 'antd';
import { useGlobalStore } from '../store/module';
import { passwordVerify } from '../components/BaseRequest';
import Input from '../components/base/Input';
import LocaleSelector from '../components/settingGroup/LocaleSelector'
import { getData } from '../components/MyStorage';
import { VPNComponent } from '../components/TestVpn';
import { MorphProtocolTestHub } from '../components/MorphProtocolTestHub';

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

    //test ping
    async function testSinglePing() {

        console.log('singleResult', `开始 ping ${address}...`, 'loading');

        try {
            const startTime = Date.now();
            const latency = await window.PingBridge.ping(address);
            const totalTime = Date.now() - startTime;

            if (latency !== null) {
                console.log('singleResult', `✅ 成功！平均延迟: ${latency} ms`, 'success');
                console.log('singleResult', `总耗时: ${totalTime} ms`, 'info');
            } else {
                console.log('singleResult', `❌ 超时或失败`, 'error');
            }
        } catch (error: any) {
            console.log('singleResult', `❌ 错误: ${error.message}`, 'error');
        }
    }

    async function testMultiplePing() {
        const addresses = ['8.8.8.8', '1.1.1.1', '141.164.34.61', '108.61.196.101', 'https://www.google.com'];

        console.log('multipleResult', `开始批量测试 ${addresses.length} 个地址...`, 'loading');

        try {
            const startTime = Date.now();
            const results = await window.PingBridge.pingMultiple(addresses);
            const totalTime = Date.now() - startTime;

            results.forEach(result => {
                if (result.latency !== null) {
                    console.log('multipleResult', `✅ ${result.address}: ${result.latency} ms`, 'success');
                } else {
                    console.log('multipleResult', `❌ ${result.address}: 超时`, 'error');
                }
            });

            console.log('multipleResult', `总耗时: ${totalTime} ms`, 'info');
        } catch (error: any) {
            console.log('multipleResult', `❌ 错误: ${error.message}`, 'error');
        }
    }

    async function testConcurrentPing() {
        const addresses = ['8.8.8.8', '1.1.1.1', '141.164.34.61', '108.61.196.101', 'https://www.google.com'];

        console.log('concurrentResult', `开始并发测试 ${addresses.length} 个地址...`, 'loading');

        try {
            const startTime = Date.now();
            const results = await window.PingBridge.pingConcurrent(addresses);
            const totalTime = Date.now() - startTime;

            results.forEach(result => {
                if (result.latency !== null) {
                    console.log('concurrentResult', `✅ ${result.address}: ${result.latency} ms`, 'success');
                } else {
                    console.log('concurrentResult', `❌ ${result.address}: 超时`, 'error');
                }
            });

            console.log('concurrentResult', `总耗时: ${totalTime} ms (并发)`, 'info');
        } catch (error: any) {
            console.log('concurrentResult', `❌ 错误: ${error?.message || String(error)}`, 'error');
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
                            className={btnstyles + ' mt-12 mb-24 w-full'}
                        >
                            {onSubmiting ? i18n.t('account.logining') as string : i18n.t('account.ok') as string}
                        </Button>

                        <Input
                            id='singleAddress'
                            type={'text'}
                            value={address}
                            onChange={e => setAddress(e.target.value)}
                            className='form-input h-12 mt-10 w-full'
                            placeholder="请输入要测试的地址"
                        />
                        <Button
                            type="text"
                            onClick={testSinglePing}
                            style={{ color: 'white', height: '44px' }}
                            className={btnstyles + ' mt-12 mb-12 w-full'}
                        >
                            单IP测试
                        </Button>
                        <Button
                            type="text"
                            onClick={testMultiplePing}
                            style={{ color: 'white', height: '44px' }}
                            className={btnstyles + ' mt-12 mb-12 w-full'}
                        >
                            多IP测试
                        </Button>
                        <Button
                            type="text"
                            onClick={testConcurrentPing}
                            style={{ color: 'white', height: '44px' }}
                            className={btnstyles + ' mt-12 mb-12 w-full'}
                        >
                            并发测试
                        </Button>
                        {/* <VPNComponent /> */}
                        <div>
                            <MorphProtocolTestHub />
                        </div>
                    </div>
                </div>

            </div>
        </>
    );
}

export default LoginPage;
