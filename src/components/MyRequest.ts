import axios, { AxiosResponse } from 'axios';
import { testGFW, forwardAxios } from './BaseRequest';
interface responseType {
    data: any;
    error: any;
}


const requestApi = async (serverIP: string, type: string, method: string, data?: any) => {
    const baseUrl = `http://${serverIP}:51821/api/wireguard/client${type}`
    // await axios({
    //     url: `http://${serverIP}:51821/api/wireguard/client${type}`,
    //     method: method,
    //     data: data,
    //     timeout: 30000
    // }).then((v) => {
    //     result.data = v.data;
    //     // console.log('BaseRequest==>>', v);
    // }).catch((err) => {
    //     result.error = err;
    //     console.log('api请求报错==>>', err.message, err.response?.data)
    // });
    // return result

    if (typeof window.gfw === 'undefined') {
        console.log('还未检查GFW,检查中...');
        await testGFW(5000);
        console.log('GFW,检查完成==>> GFW is', window.gfw);
    }

    const option = {
        method: method,
        url: baseUrl,
        data: data
    }
    let res = await forwardAxios(option,
        '4EQQGDYZSDIYTCF4WJQFLXGBCNW6EAX6FVXA',
        'https://1300369639-gw04lotgcx.ap-hongkong.tencentscf.com', window.gfw)
    let result: responseType = {
        data: res.data ? res.data : null,
        error: res.data ? null : res
    }

    window.gfw && console.log('转发请求结果==>>', result);
    return result
}

export const listConfigs = async (serverIP: string) => {
    let serverList = null;
    let flag = false, count = 0;

    while (!flag && count < 3) {
        let res = await requestApi(serverIP, '', 'get');
        if (Array.isArray(res.data)) {
            serverList = res.data;
            flag = true;
            break;
        }
        await new Promise(resolve => setTimeout(resolve, 5000));
        count++;
        console.log('list configs error=>> ', count, res.data);
    }
    return serverList
}
export const createConfigId = async (serverIP: string, userId: string) => {
    return await requestApi(serverIP, '', 'post', {
        "name": userId,
    });
}
export const createConfig = async (serverIP: string, configID: string) => {
    return await requestApi(serverIP, `/${configID}/configuration`, 'get');
}

//循环检测网络是否翻墙
export const pingGoo = (ip: string) => {
    return new Promise((resolve, reject) => {
        try {
            axios({
                url: `https://api.ipify.org?format=json`,
                method: 'get',
                timeout: 5000
            })
                .then(v => {
                    console.log('ip===>> ', v.data.ip, '=?=', ip);
                    if (v.data.ip === ip) {
                        resolve('success')
                    }
                    else {
                        resolve('ip error')
                    }

                }).catch(function (err) {
                    reject('Ping New Work Error');
                });
        }
        catch (err) {
            console.log('try ' + err);
            reject('Ping New Work Error');
        }
    })
};

export const pingGoo2 = (ip: string) => {
    return new Promise((resolve, reject) => {
        try {
            axios({
                url: `https://ipinfo.io`,
                headers: {
                    Authorization: "Bearer 5dfc814896ec0b"
                },
                method: 'get',
                timeout: 5000
            })
                .then(v => {
                    console.log('ip===>> ', v.data.ip, '=?=', ip);
                    if (v.data.ip === ip) {
                        resolve('success')
                    }
                    else {
                        resolve('ip error')
                    }

                }).catch(function (err) {
                    reject('Ping Net Work Error');
                });
        }
        catch (err) {
            console.log('try ' + err);
            reject('Ping Net Work Error');
        }
    })
};