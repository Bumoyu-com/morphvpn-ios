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

    useEffect(() => {
        setTimeout(() => {
            getStorage();
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
                            className={btnstyles + ' mt-12 mb-44 w-full'}
                        >
                            {onSubmiting ? i18n.t('account.logining') as string : i18n.t('account.ok') as string}
                        </Button>
                    </div>
                </div>

            </div>
        </>
    );
}

export default LoginPage;
