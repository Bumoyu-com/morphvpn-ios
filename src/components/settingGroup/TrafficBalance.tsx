import { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { Button } from 'antd';
import { PlusOutlined, MinusOutlined, CloseOutlined } from '@ant-design/icons';
import { useGlobalStore } from '../../store/module';
import MyModal from '../base/MyModal';

export default function TrafficBalance() {
  const { userInfo } = useGlobalStore();
  const [isOpen, setIsOpen] = useState<boolean>(false);
  const [loading, setLoading] = useState<boolean>(false);
  const [showIframe, setShowIframe] = useState<boolean>(false);
  const [count1, setCount1] = useState<number>(0);
  const [count2, setCount2] = useState<number>(0);
  const [count3, setCount3] = useState<number>(0);
  const [iframeUrl, setIframeUrl] = useState<string>('');

  const { t, i18n } = useTranslation();

  const submitBill = async () => {
    //需要补充支付逻辑
    setLoading(true);
    let doller = count1 * 10 + count2 * 20 + count3 * 30;
    let traffic = (count1 * 200 + count2 * 512 + count3 * 1024) * 1073741824;
    if (doller <= 0) {
      setLoading(false);
      return;
    }

    let payInfo = {
      id: userInfo.id,
      count: (doller * 100).toString(),
      traffic: traffic.toString()
    }
    localStorage.setItem('payInfo', JSON.stringify(payInfo));
    console.log('payInfo', payInfo, userInfo.email);
    // setIframeUrl(`http://localhost:5173/checkout?lang=${i18n.language}&userId=${payInfo.id}&quantity=${payInfo.count}&traffic=${payInfo.traffic}&email=${userInfo.email}&env=${window.baseApi === 'prod' ? 'prod' : 'dev'}`);
    setIframeUrl(`https://morphvpn.com/checkout?lang=${i18n.language}&userId=${payInfo.id}&quantity=${payInfo.count}&traffic=${payInfo.traffic}&email=${userInfo.email}&env=${window.baseApi === 'prod' ? 'prod' : 'dev'}`);
    setLoading(false);
    setShowIframe(true);
    // setIsOpen(false);
  }

  const itemGroup = (count: number, setcout: Function, data: any[]) => {
    const addCount = () => {
      setcout(count + 1)
    }
    const minusCount = () => {
      if (count > 0) {
        setcout(count - 1)
      }
    }

    return <div className="grid grid-cols-[55%_45%] h-full my-4">
      <div className="grid grid-cols-[65%_35%] px-3 py-3 border border-gray-400 rounded-md bg-indigo-600 text-left text-2xl">
        <div style={{ lineHeight: 1.4 }}>  {`${data[0]}${data[2]}`}</div>
        <div style={{ lineHeight: 1.4 }}>  {`$${data[1]}`}</div>
      </div>
      <div className='px-2 py-3'>
        <div className="float-right flex flex-row space-x-4 space-x-2 text-3xl">
          <MinusOutlined className="text-indigo-600 hover:cursor-pointer" onClick={minusCount} />
          <div>{count}</div>
          <PlusOutlined className="text-indigo-600 hover:cursor-pointer" onClick={addCount} />
        </div>
      </div>
    </div>
  }

  // 监听来自iframe的消息
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      if (event.data === 'close') {
        setShowIframe(false);
      }
    };

    window.addEventListener('message', handleMessage);

    // 组件卸载时移除监听器
    return () => {
      console.log('remove event listener');
      window.removeEventListener('message', handleMessage);
    };
  }, []);

  const btnstyles = "btn group hover:cursor-pointer w-full bg-gradient-to-t from-indigo-600 to-indigo-500 bg-[length:100%_100%] bg-[bottom] text-white shadow-[inset_0px_1px_0px_0px_theme(colors.white/.16)] hover:from-indigo-700 hover:to-indigo-400"

  return (
    <>
      <div>
        <MyModal onlyClose isOpen={isOpen} setIsOpen={setIsOpen} name={t("setting.buy")} topOffset={window.innerHeight < 800 ? 8 : 0}>
          <div className="w-full text-right">
            <CloseOutlined style={{ fontSize: 22 }} onClick={() => {
              setIsOpen(false)
              setShowIframe(false)
            }} />
          </div>

          {itemGroup(count1, setCount1, [200, 10, 'GB'])}
          {itemGroup(count2, setCount2, [0.5, 20, 'TB'])}
          {itemGroup(count3, setCount3, [1, 30, 'TB'])}

          <div className='mt-6 mb-2 border border-gray-600 border-b-1'></div>
          <div className="grid grid-cols-[25%_75%] px-3 py-2 text-xl">
            <div className="text-left">{t('setting.total')}</div>
            <div className="text-right">
              {`${(count1 / 10 + count2 / 2 + count3).toFixed(1)}TB`} {`$${(count1 * 10 + count2 * 20 + count3 * 30)}`}
            </div>
          </div>
          <Button
            type="text"
            onClick={submitBill}
            loading={loading}
            style={{ color: 'white', height: '44px' }}
            className={btnstyles + ' mt-6 mb-4 w-full'}
          >
            {t('account.ok')}
          </Button>

          <MyModal onlyClose isOpen={showIframe} setIsOpen={setShowIframe} topOffset={-24} padding={0}>
            <div style={{ width: '100%', height: '600px' }}>
              <iframe
                src={iframeUrl}
                width="100%"
                height="100%"
                style={{ border: 'none' }}
              />
            </div>
          </MyModal>

        </MyModal>


      </div>
    </>
  );
}
