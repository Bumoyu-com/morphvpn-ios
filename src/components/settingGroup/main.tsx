import { useEffect, useState } from 'react';
import { Button, Drawer } from 'antd';
import { LeftOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { Bars4Icon } from '@heroicons/react/24/outline';

import { useGlobalStore } from '../../store/module';
import { getTraffic } from '../BaseRequest';
import LocaleSelector from './LocaleSelector'
import ChangeEmail from './ChangeEmail';
import TrafficBalance from './TrafficBalance';
import { setData } from '../MyStorage';

interface VpnDrawerProps {

}
const VpnDrawer: React.FC<VpnDrawerProps> = () => {
    const { userInfo, setUserInfo } = useGlobalStore();
    const [open, setOpen] = useState(false);
    const navigate = useNavigate();
    const { i18n } = useTranslation();

    const showDrawer = async () => {
        setOpen(true);
    };
    // const checkEmail = async () => {
    //     let info = await verifyEmail(userInfo.email);
    //     console.log('getByEmail==>>', info);
    //     setUserInfo({ ...userInfo, emailVerified: info.data.emailVerified });
    // };
    const refreshTraffic = async () => {
        let info = await getTraffic(userInfo.id);
        console.log('getTraffic==>>', info.data[0]);
        setUserInfo({ ...userInfo, balance: info.data[0].traffic });
    };

    const onClose = () => {
        setOpen(false);
    };

    const handleLogout = async () => {
        let obj = {
            id: "",
            email: "",
            password: "",
            emailVerified: false,
            balance: 0,
            vpnChoose: "",
            vpnConnect: false
        }
        setUserInfo({ ...obj });
        localStorage.removeItem('globalState');
        localStorage.removeItem('payInfo');
        await setData({
            locale: i18n.language,
            userInfo: { ...obj },
            vpn: {
                useWhiteList: false,
                useLan: false,
                useExempt: false,
                exemptList: ''
            }
        });
        if (userInfo.vpnConnect) await window.morphVpn.disconnect();;

        setOpen(false);
        setTimeout(() => {
            navigate('/');
        }, 500);

    };

    const balanceCount = (balance: number) => {
        let oneGB = 1073741824;
        let newBalance = balance / oneGB;
        if (newBalance > 1024) return `${(newBalance / 1024).toFixed(2)} TB`;
        else {
            // if (balance < 10737418) return `0.01 GB`;
            return `${newBalance.toFixed(2)} GB`;
        }
    };
    const btnstyles = "btn group w-full bg-gradient-to-t from-indigo-600 to-indigo-500 bg-[length:100%_100%] bg-[bottom] text-white shadow-[inset_0px_1px_0px_0px_theme(colors.white/.16)] hover:from-indigo-700 hover:to-indigo-400"
    const drawItemStyle = "my-2 grid grid-rows-[2.5rem,minmax(0,1fr)] rounded-2xl bg-gradient-to-br from-gray-950/50 via-gray-800/25 to-gray-900/50 px-6 py-5 backdrop-blur-sm before:pointer-events-none before:absolute before:inset-0 before:rounded-[inherit] before:border before:border-transparent before:[background:linear-gradient(to_right,theme(colors.gray.800),theme(colors.gray.700),theme(colors.gray.800))_border-box] before:[mask-composite:exclude_!important] before:[mask:linear-gradient(white_0_0)_padding-box,_linear-gradient(white_0_0)]";

    useEffect(() => {
        // checkEmail();
        setTimeout(() => {
            refreshTraffic();
        }, 500);
    }, []);
    return (
        <div>
            <Bars4Icon
                onClick={showDrawer}
                className="h-8 w-8 float-right text-gray-500 transform group-hover:text-indigo-600 group-hover:cursor-pointer transition-all duration-200 cursor-pointer hover:bg-gray-800"
            />
            <Drawer title={i18n.t('setting.title')} placement="right" onClose={onClose} open={open} zIndex={49} closeIcon={<LeftOutlined style={{ color: 'white', fontSize: '24px' }} />}>
                <div className="w-full flex text-left justify-left grid grid-row-5">
                    <div className={drawItemStyle}>
                        <div className="w-full text-lg">
                            <div className="float-left">{i18n.t('setting.email')}</div>
                            <div className="float-right text-gray-100/50">{""}</div>
                        </div>

                        <div>
                            <div className="text-stone-400 float-left">{userInfo.email}</div>
                            <ChangeEmail />
                        </div>
                    </div>
                    <div className={drawItemStyle}>
                        <div className="w-full text-lg">
                            <div className="float-left">{i18n.t('setting.traffic-balance')}</div>
                            <div className="float-right text-gray-100/50">{""}</div>
                        </div>

                        <div className="w-full text-base grid grid-rows-2">
                            <div>
                                <div className="float-left">{balanceCount(userInfo.balance)}</div>
                                <TrafficBalance />
                            </div>

                            <div className="text-l mt-1">
                                <div
                                    className="text-l float-left hover:cursor-pointer"
                                    onClick={refreshTraffic}
                                    style={{ color: "#4e4eff", fontWeight: "bold" }}>
                                    {i18n.t('setting.refresh')}
                                </div>
                            </div>
                        </div>
                    </div>
                    {/* <div className={drawItemStyle}>
                        <div className="w-full text-lg">
                            <div className="float-left">{"Order"}</div>
                            <div className="float-right text-gray-100/50">{"$"}</div>
                        </div>

                        <div className="w-full text-base">
                            <div className="float-left">{"$20"}</div>
                            <div className="float-right text-gray-100/50">{"05.01.2025"}</div>
                        </div>
                        <div className="w-full text-base">
                            <div className="float-left">{"$20"}</div>
                            <div className="float-right text-gray-100/50">{"05.01.2025"}</div>
                        </div>
                    </div> */}
                    <div className={drawItemStyle}>
                        <div className="w-full text-lg">
                            <div className="float-left">{i18n.t('setting.language')}</div>
                            <div className="float-right text-gray-100/50">{""}</div>
                        </div>

                        <div className="w-full text-base">
                            <LocaleSelector />
                        </div>
                    </div>
                    <div className="w-full mt-16 text-left text-lg justify-left">
                        <Button type="text" className={btnstyles} style={{ color: 'white' }} onClick={handleLogout}>{i18n.t('setting.logout')}</Button>
                    </div>
                </div>


            </Drawer>
        </div>
    )
}

export default VpnDrawer;

