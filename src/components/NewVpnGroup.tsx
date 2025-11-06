import React, { useState, useEffect } from 'react'
import { useTranslation } from 'react-i18next';
import { Button, message } from 'antd';

import { useGlobalStore } from '../store/module';
import { listCity, getTraffic } from './BaseRequest';
import { vpnListType, extractVpnList } from './vpnList'
import { setData } from './MyStorage';
interface NewVpnGroupProps {
    onSubmit: () => void;
    connecting: boolean;
    creating: boolean;
    creatingTime: number;
}

const NewVpnGroup: React.FC<NewVpnGroupProps> = ({ onSubmit, connecting, creating, creatingTime }) => {
    const { allState, userInfo, setUserInfo } = useGlobalStore();
    const [selected, setSelected] = useState<string>('');
    const [vpnList, setVpnList] = useState<vpnListType[]>([]);

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
        let info = await getTraffic(userInfo.id);
        console.log('user admin==>>', info?.data[0]?.status === 'admin');
        const { data, error } = await listCity(99, 0);
        if (data) {
            console.log(data);
            setVpnList(extractVpnList(data, info?.data[0]?.status === 'admin'));
        }
        else {
            console.log(error);
            message.error(i18n.t('vpn.network-error'));
        }
    }

    useEffect(() => {
        renderVpnList();
        if (userInfo.vpnChoose) {
            setSelected(userInfo.vpnChoose);
        }
    }, [])

    const btnstyles = "btn group w-full bg-gradient-to-t from-indigo-600 to-indigo-500 bg-[length:100%_100%] bg-[bottom] text-white shadow-[inset_0px_1px_0px_0px_theme(colors.white/.16)] hover:from-indigo-700 hover:to-indigo-400"
    // const btnstyles = "btn-sm                bg-gradient-to-t from-indigo-600 to-indigo-500 bg-[length:100%_100%] bg-[bottom] text-white shadow-[inset_0px_1px_0px_0px_theme(colors.white/.16)] hover:bg-[length:100%_150%] py-[5px] "
    // const anime = " hover:from-indigo-500 hover:to-purple-700 active:from-indigo-700 active:to-purple-800"

    return (
        <>
            <div className='overflow-y-scroll h-2/3'>
                <div className="grid gap-x-3 gap-y-5 grid-cols-3 grid-rows-3">
                    {vpnList.map((ele: vpnListType, ind) => (
                        <div
                            key={ele.code}
                            className={
                                `${selected === ele.code ? 'bg-gradient-to-t from-indigo-600 to-indigo-500 text-white' : 'bg-gray-900 hover:bg-gray-800'} w-full     
                            relative cursor-pointer rounded-lg px-2 py-2 shadow-md focus:outline-none text-slate-200`
                            }>
                            <div className="text-center text-sm" onClick={() => handleRadioSet(ele)}>{i18n.t(`city.${ele.code}`)}</div>
                        </div>
                    ))}
                </div>
            </div>

            <Button
                type="text"
                onClick={connectVpn}
                loading={connecting}
                style={{ color: 'white', height: '44px' }}
                className={btnstyles + ' mt-12 w-full'}
            >
                {!userInfo.vpnConnect ?
                    connecting ?
                        creating ? creatingTime > 0 ? i18n.t('vpn.creatingnew', { time: creatingTime }) as string : i18n.t('vpn.creating') as string : i18n.t('vpn.connecting') as string
                        : i18n.t('vpn.connect') as string
                    : i18n.t('vpn.disconnect') as string}
            </Button>
        </>
    )
}

export default NewVpnGroup;
