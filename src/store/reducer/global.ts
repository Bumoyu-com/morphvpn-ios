import { createSlice } from '@reduxjs/toolkit';

export const globalSlice = createSlice({
  name: 'global',
  initialState: {
    locale: navigator.language.split(/[-_]/)[0] || '',
    vpn: {
      useWhiteList: false,
      useLan: false,
      useExempt: false,
      exemptList: '',
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
  },
  reducers: {
    setLocale: (state, action) => {
      state.locale = action.payload;
    },
    setVpn: (state, action) => {
      state.vpn = action.payload;
    },
    setUserInfo: (state, action) => {
      state.userInfo = action.payload;
    },
  },
});

export const { setLocale, setVpn, setUserInfo } =
  globalSlice.actions;

export default globalSlice.reducer;
