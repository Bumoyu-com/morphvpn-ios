import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

import { Button, message } from 'antd';

import { queryUser } from '../components/BaseRequest';
import Input from '../components/base/Input';

interface LoginPageProps { }
const SignupPage: React.FC<LoginPageProps> = (prop) => {
    const [userName, setuserName] = useState<string>('');
    const [userEmail, setuserEmail] = useState<string>('');
    const [userPSW, setuserPSW] = useState<string>('');
    const [secondPsw, setsecondPsw] = useState('');
    const [onSigning, setonSigning] = useState(false);

    const navigate = useNavigate();
    const { i18n } = useTranslation();

    //提交注册
    const onSubmit: any = async () => {
        console.log(userEmail, userPSW, secondPsw);

        if (!onSigning) {
            setonSigning(true);
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(userEmail)) {
                message.error(i18n.t('account.email-error'));
                setonSigning(false);
            }
            else if (userPSW !== secondPsw || (!userPSW || !secondPsw)) {
                message.error(i18n.t('account.password-wrong'));
                setonSigning(false);
            }
            else {
                const user = await queryUser(userEmail);

                if (user.data) {
                    console.log(user);
                    message.error(i18n.t('account.user-exist'));
                }
                else if (user.error) {
                    console.log(user.error);
                    if (user.error.code === 'ERR_BAD_REQUEST' || user.error.status === 404) {
                        navigate('/sverify', { state: { userName: userName, userEmail: userEmail, userPSW: userPSW } })
                    }
                    else {
                        message.error(i18n.t('account.network'));
                    }
                }
                else {
                    message.error(i18n.t('account.network'));
                    console.log('未知错误', user);
                }
                setonSigning(false);

            }
        }
    }

    const btnstyles = "btn group w-full bg-gradient-to-t from-indigo-600 to-indigo-500 bg-[length:100%_100%] bg-[bottom] text-white shadow-[inset_0px_1px_0px_0px_theme(colors.white/.16)] hover:from-indigo-700 hover:to-indigo-400"

    const anime = ""

    return (
        <>
            <div className="min-h-screen">
                <div className="h-screen fixed bottom-0 left-0 w-full flex justify-center items-end min-h-screen px-3">
                    <div className="overflow-y-scroll w-120 flex flex-col h-full justify-between pb-3 dark:bg-gray-900">
                        <div className="border border-gray-300 rounded-lg p-4 mt-10">

                            <p className="mt-12 ml-1 text-xl font-medium text-white"> {i18n.t('account.signup')}</p>
                            <Input
                                id='signup-name'
                                type={'text'}
                                value={userName}
                                onChange={e => setuserName(e.target.value)}
                                className='form-input h-12 mt-10 w-full'
                                placeholder={i18n.t('account.name')}
                            />
                            <Input
                                id='signup-email'
                                type={'text'}
                                value={userEmail}
                                onChange={e => setuserEmail(e.target.value)}
                                className='form-input h-11 mt-5 w-full'
                                placeholder={i18n.t('account.email')}
                            />
                            <Input
                                id='signup-psw'
                                type={'password'}
                                value={userPSW}
                                onChange={e => setuserPSW(e.target.value)}
                                className='form-input h-11 mt-5 w-full'
                                placeholder={i18n.t('account.password')}
                            />
                            <Input
                                id='signup-psw2'
                                type={'password'}
                                value={secondPsw}
                                onChange={e => setsecondPsw(e.target.value)}
                                className='form-input h-11 mt-5 w-full'
                                placeholder={i18n.t('account.password-check')}
                            />

                            <Button
                                type="text"
                                loading={onSigning}
                                onClick={onSubmit}
                                style={{ color: 'white', height: '44px' }}
                                className={btnstyles + anime + ' mt-20 mb-2 w-full'}
                            >
                                {i18n.t('account.ok') as string}
                            </Button>
                            <Button
                                type="text"
                                onClick={() => navigate('/')}
                                style={{ color: 'white', height: '44px' }}
                                className={btnstyles + ' mt-2 mb-10 w-full'}
                            >
                                {i18n.t('vpn.back-large')}
                            </Button>
                        </div>
                    </div>

                </div>
            </div>
        </>

    );
}

export default SignupPage;
