import { Dialog, Transition } from '@headlessui/react'
import { Fragment, useState, useRef } from 'react'
import { useTranslation } from 'react-i18next';
import TextareaAutosize from 'react-textarea-autosize';

import { useGlobalStore } from '../store/module';
import CheckBox from '../components/base/CheckBox';

export default function VpnModal() {
    const {allState, vpn, setVpn, userInfo } = useGlobalStore();

    const [isOpen, setIsOpen] = useState<boolean>(false);
    const [useWhiteList, setuseWhiteList] = useState<boolean>(vpn.useWhiteList);
    const [useLan, setuseLan] = useState<boolean>(vpn.useLan);
    const [useExempt, setuseExempt] = useState<boolean>(vpn.useExempt);
    const [ipList, setipList] = useState<string>(vpn.exemptList);

    const { i18n } = useTranslation();
    const ipListRef = useRef<HTMLTextAreaElement | null>(null);

    //确认修改设置
    function handleOk() {
        let vpnObj = {
            ...vpn,
            useWhiteList: useWhiteList,
            useLan: useLan,
            useExempt: useExempt,
            exemptList: ipList
        }
        setVpn(vpnObj)

        setIsOpen(false);
        console.log(vpn);
    }

    //取消关闭弹窗
    function closeModal() {
        setIsOpen(false)
    }

    //打开设置弹窗
    function openModal() {
        console.log(allState);
        // setIsOpen(true);
    }

    const styles = "bg-white rounded-lg px-4 py-2.5 w-full border-none focus:ring-0 focus:outline-none resize-none"

    return (
        <div>
            <div>
                {/* <span className='cursor-pointer bg-gray-900 rounded-md px-3 py-1 float-left text-slate-300' onClick={openModal}>
                    {i18n.t('vpn.rules-setting')}
                </span> */}
            </div>


            <Transition appear show={isOpen} as={Fragment}>
                <Dialog as="div" className="relative z-10" onClose={closeModal}>

                    <Transition.Child
                        as={Fragment}
                        enter="ease-out duration-300"
                        enterFrom="opacity-0"
                        enterTo="opacity-100"
                        leave="ease-in duration-200"
                        leaveFrom="opacity-100"
                        leaveTo="opacity-0"
                    >
                        <div className="fixed inset-0 bg-black bg-opacity-25" />
                    </Transition.Child>

                    <div className="fixed inset-0 overflow-y-auto">
                        <div className="flex h-full items-center justify-center p-2 text-center">
                            <Transition.Child
                                as={Fragment}
                                enter="ease-out duration-300"
                                enterFrom="opacity-0 scale-95"
                                enterTo="opacity-100 scale-100"
                                leave="ease-in duration-200"
                                leaveFrom="opacity-100 scale-100"
                                leaveTo="opacity-0 scale-95"
                            >
                                <Dialog.Panel className="h-5/6 text-sm w-full max-w-md transform overflow-hidden rounded-2xl bg-gray-950 p-6 text-left border border-gray-800 align-middle shadow-xl transition-all">
                                    <div className="text-gray-200 overflow-y-scroll h-full">

                                        <div className="font-medium leading-6">{i18n.t('vpn.setting-title')}</div>

                                        <div className="mt-14">
                                            <button
                                                type="button"
                                                className="inline-flex justify-center rounded-md border border-transparent w-full bg-gray-700 px-4 py-2 text-sm font-medium text-white hover:bg-gray-900 focus:outline-none focus-visible:ring-2 focus-visible:ring-gray-500 focus-visible:ring-offset-2"
                                                onClick={handleOk}
                                            >
                                                {i18n.t('vpn.ok')}
                                            </button>
                                        </div>
                                        <div className="mt-4">
                                            <button
                                                type="button"
                                                className="inline-flex justify-center rounded-md border border-transparent w-full bg-gray-700 px-4 py-2 text-sm font-medium text-white hover:bg-gray-900 focus:outline-none focus-visible:ring-2 focus-visible:ring-gray-500 focus-visible:ring-offset-2"
                                                onClick={closeModal}
                                            >
                                                {i18n.t('vpn.cancel')}
                                            </button>
                                        </div>
                                    </div>
                                </Dialog.Panel>
                            </Transition.Child>
                        </div>
                    </div>

                </Dialog>
            </Transition>

        </div>
    )
}


