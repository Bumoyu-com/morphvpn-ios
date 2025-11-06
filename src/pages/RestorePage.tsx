import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

import { Button, message } from 'antd';

import { useGlobalStore } from '../store/module';
import { queryUser, sendEmail, getByToken, updatePsw } from '../components/BaseRequest';
import Input from '../components/base/Input';
import { setData } from '../components/MyStorage';

interface RestorePageProps { inPage?: boolean, setIsOpen?: React.Dispatch<React.SetStateAction<boolean>> }
const RestorePage: React.FC<RestorePageProps> = ({ inPage, setIsOpen }) => {
    const { allState, setUserInfo, userInfo } = useGlobalStore();

    const [userEmail, setuserEmail] = useState<string>('');
    const [userPSW, setuserPSW] = useState<string>('');
    const [secondPsw, setsecondPsw] = useState('');

    const [userPhoneCode, setuserPhoneCode] = useState<string>('');
    const [onSending, setOnSending] = useState(false);
    const [codeTime, setcodeTime] = useState(60);

    const navigate = useNavigate();
    const { i18n } = useTranslation();

    //发送验证码请求
    const sendCode: any = async () => {
        if (!userEmail || !userEmail.includes('@')) {
            message.error(i18n.t('account.email-error'));
            return;
        }

        const user = await queryUser(userEmail);

        if (user.data) {
            console.log(user);
        }
        if (user.error) {
            console.log('network err', user.error);
            message.error(i18n.t('account.user-notexist'));
            return
        }

        setOnSending(true);
        const { data, error } = await sendEmail(userEmail);
        if (data) {
            console.log('发送成功', data);
            message.success(i18n.t('account.code-over'));
        }
        if (error) {
            console.log('sendcode network err', error);
            message.error(i18n.t('account.code-failed'));
        }
    }

    //提交验证code，修改密码
    const onSubmit: any = async () => {
        if (!userEmail || !userEmail.includes('@')) {
            message.error(i18n.t('account.email-error'));
            return;
        }

        if (!userPSW || !secondPsw) {
            message.error(i18n.t('account.password-wrong'));
            return;
        }
        if (userPSW !== secondPsw) {
            message.error(i18n.t('account.password-wrong'));
            return;

        }
        console.log(userEmail, userPSW, secondPsw, userPhoneCode);

        if (userPhoneCode) {
            const { data, error } = await getByToken(userPhoneCode);
            if (data) {
                console.log('验证已发送', data);
                let haveMyEmail = false
                for (let i = 0; i < data.length; i++) {
                    if (data[i].email === userEmail) {
                        haveMyEmail = true
                        console.log('找到了', data[i]);
                        break
                    }
                }
                if (haveMyEmail) {
                    await restoreHook(userEmail, userPSW);
                }
                else {
                    message.error(i18n.t('account.code-wrong'));
                }
            }
            else {
                console.log('验证失败', error);
                message.error(i18n.t('account.network'));
            }
        }
        else {
            message.error(i18n.t('account.code-wrong'));
        }
    }


    // 修改密码请求
    const restoreHook = async (email: string, newPSW: string) => {
        const { data, error } = await updatePsw(email, newPSW);

        if (data) {
            console.log(data);
            if (data.success) {
                if (inPage && setIsOpen) {
                    let newInfo = { ...userInfo, password: newPSW };
                    setUserInfo(newInfo);
                    try {
                        await setData({ ...allState, userInfo: newInfo });
                    } catch { }
                    setIsOpen(false);
                }
                else {
                    message.success(i18n.t('account.password-success'))
                    setTimeout(() => {
                        navigate('/')
                    }, 1000);
                }
            }
            else {
                message.error(i18n.t('account.code-wrong'))
            }
        }
        if (error) {
            console.log('network err', error);
            message.error(i18n.t('account.code-wrong'))
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

    useEffect(() => {
        if (userInfo.email) {
            setuserEmail(userInfo.email);
        }
    }, []);

    const btnstyles = "btn group w-full bg-gradient-to-t from-indigo-600 to-indigo-500 bg-[length:100%_100%] bg-[bottom] text-white shadow-[inset_0px_1px_0px_0px_theme(colors.white/.16)] hover:from-indigo-700 hover:to-indigo-400"
    const anime = " hover:from-indigo-500 hover:to-purple-700 active:from-indigo-700 active:to-purple-800"

    const items = (
        <>
            <p className={`${inPage ? 'mt-8' : 'mt-12'} ml-1 text-xl font-medium text-white`}> {i18n.t('account.restore')}</p>
            {inPage ?
                <p className="my-7 ml-1 text-lg font-medium text-white"> {userEmail}</p>
                : <Input
                    id='restore-email'
                    type={'text'}
                    value={userEmail}
                    onChange={e => setuserEmail(e.target.value)}
                    className='form-input h-12 mt-10 w-full'
                    placeholder={i18n.t('account.email')}
                />
            }

            <Input
                id='restore-psw'
                type={'password'}
                value={userPSW}
                onChange={e => setuserPSW(e.target.value)}
                className='form-input h-11 mt-5 w-full'
                placeholder={i18n.t('account.newpsw')}
            />
            <Input
                id='restore-psw2'
                type={'password'}
                value={secondPsw}
                onChange={e => setsecondPsw(e.target.value)}
                className='form-input h-11 mt-5 w-full'
                placeholder={i18n.t('account.password-check')}
            />


            <Input
                id='restore-vcode'
                type={'text'}
                value={userPhoneCode}
                onChange={e => setuserPhoneCode(e.target.value)}
                className={`form-input float-left w-6/12 mt-6 h-11`}
                placeholder={i18n.t('account.code')}
            />

            <div className='float-right w-5/12 mt-6'>
                <Button
                    type="text"
                    disabled={onSending}
                    onClick={sendCode}
                    style={{ color: 'white', height: '44px' }}
                    className={btnstyles + (onSending ? '' : anime)}>
                    {onSending ? (codeTime + ' s') : i18n.t('account.code-send') as string}
                </Button>
            </div>

            <Button
                type="text"
                onClick={onSubmit}
                style={{ color: 'white', height: '44px' }}
                className={btnstyles + (inPage ? ' my-16' : ' mt-20') + ' w-full'}
            >
                {i18n.t('account.ok') as string}
            </Button>
            {!inPage && <Button
                type="text"
                onClick={() => navigate('/')}
                style={{ color: 'white', height: '44px' }}
                className={btnstyles + ' mt-4 mb-10 w-full'}
            >
                {i18n.t('vpn.back-large')}
            </Button>}
        </>
    )

    return (
        <>
            {inPage ?
                <>
                    {items}
                </>
                :
                <div className="min-h-screen">
                    <div className="h-screen fixed bottom-0 left-0 w-full flex justify-center items-end min-h-screen px-3">
                        <div className="overflow-y-scroll w-120 flex flex-col h-full justify-between pb-3 dark:bg-gray-900">
                            <div className="border border-gray-300 rounded-lg p-4 mt-10">
                                {items}
                            </div>
                        </div>
                    </div>
                </div>}

        </>

    );
}

export default RestorePage;
