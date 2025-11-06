import { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { GlobalOutlined } from '@ant-design/icons';
import { useGlobalStore } from '../../store/module';
import { setData } from '../MyStorage';
import MyModal from '../base/MyModal';

interface LoginPageProps { simple?: boolean }
const LanguageSelector = ({ simple }: LoginPageProps) => {
  const [isOpen, setIsOpen] = useState<boolean>(false);
  const { t, i18n } = useTranslation();
  const { allState, locale, setLocale } = useGlobalStore();

  useEffect(() => {
    if (!simple) {
      if (locale === '') {
        const browserLanguage = navigator.language.split(/[-_]/)[0];
        setLocale(browserLanguage);

      }
      setTimeout(() => {
        i18n.changeLanguage(locale);
        setData(allState);
      }, 100);
    }
  }, [locale]);

  const languages: string[] = ['en', 'cn', 'tw', 'ru', 'de', 'vi', 'ar', 'fa', 'ur'];

  const btnstyles = "btn group hover:cursor-pointer w-full bg-gradient-to-t from-indigo-600 to-indigo-500 bg-[length:100%_100%] bg-[bottom] text-white shadow-[inset_0px_1px_0px_0px_theme(colors.white/.16)] hover:from-indigo-700 hover:to-indigo-400"

  return (
    <>
      {simple ?
        <MyModal isOpen={isOpen} setIsOpen={setIsOpen} name={<GlobalOutlined onClick={() => setIsOpen(true)} style={{ position: 'absolute', right: 18, top: 68, color: 'white', fontSize: '20px' }} />}>

          <div className="text-gray-200 overflow-y-scroll h-full">
            {languages.map(language => {
              return <div
                key={language}
                className={`text-center hover:cursor-pointer leading-6 my-2 py-2 ${locale === language && 'bg-gray-800'} hover:bg-gray-900`}
                onClick={() => {
                  setLocale(language);
                  setData({ ...allState, locale: language });
                  i18n.changeLanguage(language);
                }}>
                {t(`language.${language}`)}
              </div>
            })}
            <div className="mt-14 mb-2">
              <div className="w-full text-left justify-left">
                <div className={btnstyles} style={{ color: 'white' }} onClick={() => setIsOpen(false)}> {i18n.t('vpn.ok')}</div>
              </div>
            </div>
          </div>
        </MyModal>
        :
        <>
          <div className="text-stone-400 float-left">{t(`language.${locale}`)}</div>
          <div>
            <MyModal isOpen={isOpen} setIsOpen={setIsOpen} name={t("setting.change")}>
              <div className="text-gray-200 overflow-y-scroll h-full">
                {languages.map(language => {
                  return <div
                    key={language}
                    className={`text-center hover:cursor-pointer leading-6 my-2 py-2 ${locale === language && 'bg-gray-800'} hover:bg-gray-900`}
                    onClick={() => setLocale(language)}>{t(`language.${language}`)}
                  </div>
                })}
                <div className="mt-14 mb-2">
                  <div className="w-full text-left justify-left">
                    <div className={btnstyles} style={{ color: 'white' }} onClick={() => setIsOpen(false)}> {i18n.t('vpn.ok')}</div>
                  </div>
                </div>
              </div>
            </MyModal>

          </div>
        </>
      }
    </>
  );
}

export default LanguageSelector;
