import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import arLocale from './locales/ar.json';
import cnLocale from './locales/cn.json';
import deLocale from './locales/de.json';
import enLocale from './locales/en.json';
import faLocale from './locales/fa.json';
import ruLocale from './locales/ru.json';
import twLocale from './locales/tw.json';
import urLocale from './locales/ur.json';
import viLocale from './locales/vi.json';
import { getData } from './components/MyStorage';


const locales = ['zh', 'en', 'ar', 'fa', 'de', 'ur', 'vi', 'ru'];
function getLocaleFromLocalStorage() {
  let lang = navigator.language.split(/[-_]/)[0]
  if (locales.includes(lang)) {
    if (lang === 'zh') {
      return 'cn';
    }
    return lang;
  }
  return 'en';
}

i18n
  .use(initReactI18next)
  .init({
    resources: {
      ar: {
        translation: arLocale,
      },
      cn: {
        translation: cnLocale,
      },
      de: {
        translation: deLocale,
      },
      en: {
        translation: enLocale,
      },
      fa: {
        translation: faLocale,
      },
      ru: {
        translation: ruLocale,
      },
      tw: {
        translation: twLocale,
      },
      ur: {
        translation: urLocale,
      },
      vi: {
        translation: viLocale,
      }
    },
    fallbackLng: getLocaleFromLocalStorage(),
  })
  .then(async function (t) {
    let userData = await getData();
    if (userData) {
      i18n.changeLanguage(JSON.parse(userData).locale);
    }
  });

export default i18n;
