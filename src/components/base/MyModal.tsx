import { Dialog, Transition } from '@headlessui/react'
import { Fragment } from 'react'

export default function MyModal({
    name, children, isOpen, setIsOpen, topOffset, padding = 6, onlyClose
}: {
    name?: string | React.ReactNode | undefined | null,
    children: React.ReactNode,
    isOpen: boolean,
    setIsOpen: React.Dispatch<React.SetStateAction<boolean>>,
    topOffset?: number,
    padding?: number,
    onlyClose?: boolean
}) {
    return (
        <div>
            {name ?
                typeof name === 'string' ?
                    <div className="text-l float-right hover:cursor-pointer" onClick={() => setIsOpen(true)} style={{ color: "#4e4eff", fontWeight: "bold" }}>{name}</div>
                    : <>{name}</>
                : <></>
            }
            <Transition appear show={isOpen} as={Fragment}>
                <Dialog as="div" className="relative z-50" onClose={() => setIsOpen(onlyClose ? true : false)}>
                    <div className="fixed inset-0 bg-black/60" aria-hidden="true" />
                    <div className="fixed inset-0 overflow-y-auto">
                        <div className="flex h-full items-center justify-center p-2 text-center">
                            <Transition.Child
                                as={Fragment}
                                enter="ease-out duration-300"
                                enterFrom="opacity-0 scale-95"
                                enterTo="opacity-100 scale-100"
                                leave="ease-in duration-100"
                                leaveFrom="opacity-100 scale-100"
                                leaveTo="opacity-0 scale-95"
                            >
                                <Dialog.Panel className={`mb-${topOffset ? 32 - topOffset : 32} p-${padding} text-sm w-full max-w-md transform overflow-hidden rounded-2xl bg-gray-950 text-left border border-gray-600 align-middle shadow-xl transition-all`}>
                                    <div className="text-gray-200 overflow-y-scroll h-full">
                                        {children}
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


