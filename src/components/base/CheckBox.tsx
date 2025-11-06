export interface CheckBoxProps {
    onClick?: () => void;
    title?: string;
    content?: string | React.ReactNode;
    disabled?: boolean;
    children?: React.ReactNode;
}


export function CheckIconFill(props: any) {
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

export function CheckIconEmpty(props: any) {
    return (
        <svg viewBox="0 0 24 24" fill="none" {...props}>
            <circle cx={12} cy={12} r={11} stroke="#000" strokeWidth={1.5} />
        </svg>
    )
}

function CheckBox({ onClick, title, content, disabled, children }: CheckBoxProps) {
    return (
        <>
            <div
                className='mt-5 bg-gray-300 bg-opacity-75 relative flex rounded-lg px-3 py-2 shadow-md'
            >
                <div className="w-full items-center justify-start">
                    <div onClick={onClick} className="flex flex-none ">
                        <div className={"shrink-0 w-5 mr-2 text-gray-900 rounded-full" + (disabled && ' bg-gray-900')}>
                            {disabled ? <CheckIconFill className="h-5 w-5" /> : <CheckIconEmpty className="h-5 w-5" />}
                        </div>
                        <span className='text-gray-800'>{title}</span>
                    </div>
                    {children}
                </div>
            </div>
            <p className='mt-3 mb-8'>{content}</p>
        </>

    );
}

export default CheckBox;
