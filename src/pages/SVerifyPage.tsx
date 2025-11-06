import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useTranslation, Trans } from 'react-i18next';
import { Thumbmark } from "@thumbmarkjs/thumbmarkjs";

import { Button, message } from 'antd';
import { useGlobalStore } from '../store/module';
import { createUser, createVpnUser, sendEmail, getByToken } from '../components/BaseRequest';
import MyModal from '../components/base/MyModal';
import Input from '../components/base/Input';

interface SignVerifyPageProps { }
const SignVerifyPage: React.FC<SignVerifyPageProps> = (prop) => {
    const { userInfo, setUserInfo } = useGlobalStore();

    const [userPhoneCode, setuserPhoneCode] = useState<string>('');
    const [onSending, setOnSending] = useState(false);
    const [scLoading, setScLoading] = useState(false);
    const [onSubmiting, setOnSubmiting] = useState(false);
    const [codeTime, setcodeTime] = useState(60);
    const [isOpen, setIsOpen] = useState<boolean>(false);

    const navigate = useNavigate();
    const location = useLocation();
    const { t } = useTranslation();

    const tPromise = new Thumbmark({
        api_key: "916a2066c5acfb500bba40d23fe314fe",
        exclude: ['fonts', 'permissions']
    });

    //发送验证码请求
    const sendCode: any = async () => {
        setScLoading(true);
        const { data, error } = await sendEmail(location.state.userEmail);
        if (data) {
            console.log('发送成功', data);
            message.success(t('account.code-over'));
            setOnSending(true);
        }
        else {
            console.log('发送失败', error);
            message.error(t('account.code-failed'));
        }
        setScLoading(false);
    }

    //提交验证code
    const onSubmit: any = async () => {
        console.log('code', userPhoneCode);
        if (userPhoneCode) {
            setOnSubmiting(true);
            const { data, error } = await getByToken(userPhoneCode);
            if (data) {
                console.log('验证已发送', data);
                let haveMyEmail = false
                for (let i = 0; i < data.length; i++) {
                    if (data[i].email === location.state.userEmail) {
                        haveMyEmail = true
                        console.log('找到了', data[i]);
                        break
                    }
                }
                if (haveMyEmail) {

                    try {
                        let tm = await tPromise.get();
                        if (!tm) {
                            throw new Error('thumbmark empty')
                        }
                        console.log('tm result', tm);
                        let info = {
                            components: {},
                            info: {}
                        }
                        info.components = tm.components
                        info.info = tm.info

                        await signupHook(location.state.userName, location.state.userEmail, location.state.userPSW, tm.visitorId, JSON.stringify(info));
                    } catch (error) {
                        console.log('thumbmark error', error)
                        message.error(t('account.network'));
                    }
                }
                else {
                    message.error(t('account.code-wrong'));
                }
            }
            else {
                console.log('验证失败', error);
                message.error(t('account.network'));
            }
            setOnSubmiting(false);
        }
        else {
            message.error(t('account.code-wrong'));
        }
    }

    //注册账号
    const signupHook = async (name: string, email: string, password: string, visitorId: string, thumbmark: string) => {

        const { data, error } = await createUser(name, email, password, visitorId, thumbmark);
        if (data) {
            console.log('用户注册结果', data);
            if (data.id) {
                const { data: data2, error: error2 } = await createVpnUser(data.id);
                if (data2) {
                    console.log('vpn注册成功', data2);
                    message.success(t('account.code-right'));
                    setUserInfo({ ...userInfo, id: data.id, email: data.email, password: password, vpnChoose: data2.vpnChoose });
                    navigate('/vpn')
                }
                else {
                    message.error(t('account.vpn-create-failed'), 5);
                    console.error('vpn注册失败', error2);
                }

            }
            else {
                if (data.msg === 'reject') {
                    setIsOpen(true);
                }
                else {
                    message.error(t('account.user-create-failed'), 5);
                    console.error('用户注册失败', data);
                }
            }
        }

        if (error) {
            console.log(error, error.response.status);
            if (error.response?.status === 500) {
                message.error(t('account.user-exist'));
            }
            else {
                message.error(t('account.network'));
            }
        }
    };

    //验证码间隔倒计时
    useEffect(() => {
        if (onSending) {
            let time = 60;
            var aa = setInterval(function () {
                if (time > 0) {
                    time -= 1;
                    setcodeTime(time);
                }
                else {
                    setcodeTime(60);
                    setOnSending(false);
                    clearInterval(aa);
                }
            }, 1000);
        }
    }, [onSending]);

    const btnstyles = "font-medium w-full shadow text-center rounded-lg bg-gradient-to-tr from-indigo-500 to-purple-500 transition-colors duration-300"
    const anime = " hover:from-indigo-500 hover:to-purple-700 active:from-indigo-700 active:to-purple-800"

    const rejectInfo = (
        <div className="rounded-lg shadow-lg p-6 max-w-lg mx-auto">
            {/* 标题区域 */}
            <div className="border-b border-gray-200 pb-3 mb-4">
                <h3 className="text-xl font-bold text-red-600">
                    {t('RegisterFailed.title')}
                </h3>
            </div>

            {/* 错误信息 */}
            <div className="mb-5">
                <p className="text-gray-200 mb-3">
                    {t('RegisterFailed.description')}
                </p>

                <ul className="list-disc pl-5 space-y-2">
                    <li>
                        <Trans
                            i18nKey="RegisterFailed.reason.duplicate"
                            components={{ bold: <span className="font-semibold" /> }}
                        />
                    </li>
                    <li>
                        <Trans
                            i18nKey="RegisterFailed.reason.emulator"
                            components={{ bold: <span className="font-semibold" /> }}
                        />
                    </li>
                </ul>
            </div>


            <Button
                type="text"
                onClick={() => navigate('/')}
                style={{ color: 'white', height: '44px' }}
                className={btnstyles + ' mt-8 mb-2 w-full'}
            >
                {t('vpn.back-large')}
            </Button>
        </div>
    )

    return (
        <div className="min-h-screen">
            <div className="h-screen fixed bottom-0 left-0 w-full flex justify-center items-end min-h-screen px-3">
                <div className="overflow-y-scroll w-120 flex flex-col h-full justify-between pb-3 dark:bg-gray-900">
                    <div className="border border-gray-300 rounded-lg p-4 mt-10">

                        <p className="mt-12 mb-2 ml-1 text-lg font-medium text-white"> {t('account.sverify-title')}</p>
                        <p className="mt-4 mb-4 ml-1 text-lg font-medium text-white"> {location.state.userEmail}</p>
                        <Input
                            id='vcode'
                            type={'text'}
                            value={userPhoneCode}
                            onChange={e => setuserPhoneCode(e.target.value)}
                            className={`form-input float-left w-6/12 mt-5 h-11`}
                            placeholder={t('account.code')}
                        />
                        <div className='float-right w-5/12 mt-5'>
                            <Button
                                type="text"
                                disabled={onSending}
                                loading={scLoading}
                                onClick={sendCode}
                                style={{ color: 'white', height: '44px' }}
                                className={btnstyles + (onSending ? '' : anime)}>
                                {onSending ? (codeTime + ' s') : t('account.code-send') as string}
                            </Button>
                        </div>

                        <Button
                            type="text"
                            loading={onSubmiting}
                            onClick={onSubmit}
                            style={{ color: 'white', height: '44px' }}
                            className={btnstyles + anime + ' mt-20 mb-2 w-full'}
                        >
                            {t('account.ok') as string}
                        </Button>
                        <Button
                            type="text"
                            onClick={() => navigate('/')}
                            style={{ color: 'white', height: '44px' }}
                            className={btnstyles + ' mt-2 mb-24 w-full'}
                        >
                            {t('vpn.cancel')}
                        </Button>
                    </div>
                </div>
                <MyModal onlyClose isOpen={isOpen} setIsOpen={setIsOpen}>
                    <div className="text-gray-200 overflow-y-scroll h-full">
                        {rejectInfo}
                    </div>
                </MyModal>
            </div>
        </div>
    );
}

export default SignVerifyPage;
