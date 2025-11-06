import { useSelector, useDispatch } from 'react-redux';
import { useEffect } from 'react';

import { Decrypt, Encrypt } from '../../components/CryptoTools'
import store from '../index';

function deepMerge(obj1: any, obj2: any) {
  const result = { ...obj1 };

  for (const key in obj2) {
    if (obj2.hasOwnProperty(key)) {
      if (typeof obj2[key] === 'object' && obj2[key] !== null && !Array.isArray(obj2[key])) {
        result[key] = deepMerge(obj1[key], obj2[key]);
      }
      else {
        if (key !== 'vpnConnect') result[key] = obj2[key];
        else {
          result[key] = obj1[key];
        }
      }
    }
  }

  return result;
}

const defaultGlobalState = {
  locale: navigator.language.split(/[-_]/)[0] || '',
  vpn: {
    useWhiteList: false,
    useLan: false,
    useExempt: false,
    exemptList: ''
  },
  userInfo: {
    id: "",
    email: "",
    password: "",
    emailVerified: false,
    balance: 0,
    vpnChoose: "",
    vpnConnect: false
  }
};

export const initialGlobalState = () => {
  let stateJson = localStorage.getItem('globalState');

  if (stateJson) {
    let storedState = Decrypt(stateJson);
    // Merge storedState with defaultGlobalState
    let state = deepMerge(defaultGlobalState, storedState);

    // Update each property in the store
    for (let [key, value] of Object.entries(state)) {
      store.dispatch({
        type: `global/set${key.charAt(0).toUpperCase() + key.slice(1)}`,
        payload: value,
      });
    }

    // Save the updated state back to localStorage
    localStorage.setItem('globalState', Encrypt(JSON.stringify(state)));
  } else {
    // Save the defaultGlobalState to localStorage
    localStorage.setItem('globalState', Encrypt(JSON.stringify(defaultGlobalState)));
  }
};

const selectGlobal = (state: any) => state.global;

const saveStateToLocalStorage = (state: any) => {
  localStorage.setItem('globalState', Encrypt(JSON.stringify(state)));
};

export const useGlobalStore = () => {
  const dispatch = useDispatch();

  const state = useSelector(selectGlobal);
  const allState = { ...state };
  useEffect(() => {
    // Subscribe to state changes
    const unsubscribe = store.subscribe(() => {
      saveStateToLocalStorage(store.getState().global);
    });

    // Clean up the subscription on unmount
    return () => {
      unsubscribe();
    };
  }, []);

  const setLocale = (locale: string) => {
    dispatch({ type: 'global/setLocale', payload: locale });
  };
  const setVpn = (vpn: any) => {
    dispatch({ type: 'global/setVpn', payload: vpn });
  };
  const setUserInfo = (uesrInfo: any) => {
    dispatch({ type: 'global/setUserInfo', payload: uesrInfo });
  };

  return {
    allState,
    ...state,
    setLocale,
    setVpn,
    setUserInfo
  };
};
