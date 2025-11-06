import React, { useState, useEffect } from 'react'
import { RadioGroup } from '@headlessui/react'
import { useTranslation } from 'react-i18next';
import { Button, message } from 'antd';

import { useGlobalStore } from '../store/module';
// import Button from '../components/base/Button';

interface VpnGroupProps {
    vpnList: Array<{
        name: string;
        name_cn: string;
        wgAddr: string;
        wgPort: number;
    }> | [];
    onSubmit: () => void;
    connecting: boolean;
}
const VpnGroup: React.FC<VpnGroupProps> = ({ vpnList, onSubmit, connecting }) => {
    const { userInfo, setUserInfo } = useGlobalStore();
    const [plans, setplans] = useState<any[]>([]);
    const [selected, setSelected] = useState(null);

    const { i18n } = useTranslation();

    //选择vpn
    const handleRadioSet = (e: any) => {
        console.log(e);
        setSelected(e);
        setUserInfo({ ...userInfo, vpnChoose: e });
    }

    //调用连接vpn
    const connectVpn = async () => {
        if (connecting) return
        if (userInfo.vpnChoose) {
            onSubmit();
        }
        else message.error(i18n.t('vpn.no-selected'));
    }


    useEffect(() => {
        if (userInfo.vpnChoose) {
            console.log('我加载啦');
            setSelected(userInfo.vpnChoose);
        }
    }, [])

    useEffect(() => {
        var arr = []
        for (let i = 0; i < vpnList.length; i++) {
            let str = vpnList[i].name_cn + '##' + vpnList[i].name + '##' + vpnList[i].wgAddr
            arr.push(str)
        }
        console.log('vpnList', arr);

        setplans([...arr]);
    }, [vpnList, i18n.language])

    const btnstyles = "font-medium w-full shadow text-center rounded-lg bg-gradient-to-tr from-indigo-500 to-purple-500 transition-colors duration-300"
    const anime = " hover:from-indigo-500 hover:to-purple-700 active:from-indigo-700 active:to-purple-800"

    return (
        <>
            <div className='overflow-y-scroll h-2/3'>
                <RadioGroup value={selected} onChange={handleRadioSet}>
                    <div className="space-y-4 pt-2 pb-10">
                        {plans && plans.map((plan, ind) => (
                            <RadioGroup.Option
                                key={plan + ind}
                                value={plan}
                                className={({ active, checked }) =>
                                    `${checked ? 'bg-sky-700 bg-opacity-75 text-white' : 'bg-white'}
                                relative flex cursor-pointer rounded-lg px-3 py-4 shadow-md focus:outline-none`
                                }
                            >
                                {({ active, checked }) => (
                                    <>
                                        <div className="flex flex-none w-full items-center justify-start">

                                            <div className="shrink-0 text-white w-6 mr-2">
                                                {checked ? <CheckIcon className="h-6 w-6" /> : <div className="h-6 w-6" ></div>}
                                            </div>

                                            <RadioGroup.Description
                                                as="span"
                                                className={`inline grid grid-cols-9 text-center text-sm w-11/12 ${checked ? 'text-sky-100' : 'text-gray-500'}`}
                                            >

                                                <span className='col-span-3 sm:col-span-3'>{i18n.language === 'zh' ? plan.split('##')[0] : plan.split('##')[1]}</span>
                                                <span className='col-span-2 sm:col-span-2'></span>
                                                <span className='col-span-3 sm:col-span-3 text-green-400'>
                                                    {checked && userInfo.vpnConnect ? i18n.t('vpn.connected') : ''}
                                                </span>

                                            </RadioGroup.Description>
                                        </div>
                                    </>
                                )}
                            </RadioGroup.Option>
                        ))}
                    </div>
                </RadioGroup>
            </div>

            <Button
                type="text"
                onClick={connectVpn}
                loading={connecting}
                style={{ color: 'white', height: '44px' }}
                className={btnstyles + anime + ' mt-6 w-full'}
            >
                {!userInfo.vpnConnect ? i18n.t('vpn.connect') as string : i18n.t('vpn.disconnect') as string}
            </Button>

            {/* <Button
                onClick={connectVpn}
                className={btnstyles + ' mt-10 sm:mt-6 w-full'}
                text={!userInfo.vpnConnect ? i18n.t('vpn.connect') as string : i18n.t('vpn.disconnect') as string}
            /> */}
        </>
    )
}

function CheckIcon(props: any) {
    return (
        <svg viewBox="0 0 24 24" fill="none" {...props}>
            <circle cx={12} cy={12} r={12} fill="#fff" opacity="0.2" />
            <path
                d="M7 13l3 3 7-7"
                stroke="#fff"
                strokeWidth={1.5}
                strokeLinecap="round"
                strokeLinejoin="round"
            />
        </svg>
    )
}

export default VpnGroup;
