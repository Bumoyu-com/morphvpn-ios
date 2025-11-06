import axios, { AxiosResponse } from 'axios';

interface responseType {
    data: any;
    error: any;
}

export const testGFW = async (timeout: number) => {
    await axios({
        url: 'https://www.google.com/',
        method: 'get',
        timeout: timeout
    }).then((v) => {
        console.log('testGFW==>>', v);
    }).catch((err) => {
        if (err.message === 'timeout of ' + timeout + 'ms exceeded') {
            window.gfw = true;
        }
        else if (err.message === 'Network Error') {
            window.gfw = false;
        }
        else {
            console.log('testGFW error==>>', err)
        }

    });
};



export async function forwardAxios(option: any, authKey: string, requestForwardUrl: string, requestForward: boolean): Promise<any> {
    if (!authKey) {
        return Promise.resolve('authKey is not ready, try later.')
    }
    if (option.headers) {
        option.headers.Authorization = authKey
    }
    else {
        option.headers = { Authorization: authKey }
    }
    //to-do: encryte payload
    const axiosOption = option
    if (requestForward) {
        let result = await axios({
            method: 'post',
            url: requestForwardUrl,
            data: axiosOption
        })
            .then(function (response: AxiosResponse) {
                // You can now work with the JSON response data directly
                response.status = response.data.status
                response.data = response.data.data
                return response
            })
            .catch(function (error: any) {
                // console.log('axios error：', error);
                return error
            });
        return result
    }
    else {
        let result = await axios(axiosOption)
            .then(function (response: AxiosResponse) {
                // You can now work with the JSON response data directly
                return response
            })
            .catch(function (error: any) {
                // console.log('axios error：', error);
                return error
            });
        return result
    }
}

const requestApi = async (type: string, method: string, data: any) => {
    const baseUrl = window.baseApi === 'prod' ? 'https://bumoyu-saas-morphvpn-api-prod.zhendong-ge.workers.dev' : 'https://bumoyu-saas-morphvpn-api.zhendong-ge.workers.dev'
    if (typeof window.gfw === 'undefined') {
        console.log('还未检查GFW,检查中...');
        await testGFW(5000);
        console.log('GFW,检查完成==>> GFW is', window.gfw);
        console.log('baseUrl==>>', baseUrl);
    }

    const option = {
        method: method,
        url: baseUrl + type,
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
/**** user相关 ****/
//注册
export const createUser = async (name: string, email: string, password: string, deviceId: string, thumbmark: string) => {
    return await requestApi('/db/user', 'post', {
        'name': name,
        'email': email,
        'password': password,
        'deviceId': deviceId,
        'thumbmark': thumbmark
    });
}
//注册补充vpnid
export const createVpnUser = async (id: string) => {
    return await requestApi('/db/morphVpn_user', 'post', {
        'userId': id
    });
}
//发送邮箱验证码
export const sendEmail = async (email: string) => {
    return await requestApi('/api/email/send', 'post', {
        'email': email
    });
}
//验证邮箱验证码
export const getByToken = async (token: string) => {
    return await requestApi('/db/verificationToken/getByToken', 'post', {
        'token': token
    });
}


//查询
export const queryUser = async (email: string) => {
    return await requestApi('/db/user/getByEmail', 'post', {
        email: email
    });
}
//删除
export const deleteUser = async (email: string) => {
    return await requestApi('/db/user/deleteByEmail', 'post', {
        email: email
    });
}
//登录
export const passwordVerify = async (email: string, password: string) => {
    return await requestApi('/db/user/passwordVerify', 'post', {
        email: email,
        password: password
    });
}
//改密
export const updatePsw = async (email: string, password: string) => {
    return await requestApi('/db/user/updateByEmail', 'post', {
        email: email,
        password: password
    });
}
//验证
export const verifyEmail = async (email: string) => {
    return await requestApi('/db/user/getByEmail', 'post', {
        email: email
    });
}
//查浏览
export const getTraffic = async (userId: string) => {
    return await requestApi('/db/morphVpn_user/getByUserId', 'post', {
        userId: userId
    });
}
//记录付款
export const payment = async (userId: string, amount: number) => {
    return await requestApi('/db/payment', 'post', {
        userId: userId,
        amount: amount
    });
}
//增加流量
export const addTraffic = async (userId: string, traffic: number) => {
    return await requestApi('/db/morphVpn_user/addTrafficByUserId', 'post', {
        id: userId,
        traffic: traffic
    });
}

export const sendCodeApi = (email: string, id: string) => {
    let result: responseType = {
        data: {},
        error: ''
    }
    axios({
        url: "https://h014xxwal1.execute-api.ap-east-1.amazonaws.com/code",
        method: 'post',
        headers: {
            'Content-Type': 'application/json',
        },
        data: {
            email: email,
            id: id
        },
        timeout: 60000
    }).then(v => {
        result.data = v.data;
        console.log('BaseRequest==>>', v.data);
    }).catch((err) => {
        result.error = err.message;
        console.log('api请求报错==>>', err.message, err.response?.data)
    });
    return result
}

/**** vpn相关 ****/
export const listCity = async (limit: number, offset: number) => {
    return await requestApi('/db/morphVpn_city/list', 'post', {
        'limit': limit,
        'offset': offset
    });
}
export const listServer = async (limit: number, offset: number) => {
    return await requestApi('/db/morphVpn_server/list', 'post', {
        'limit': limit,
        'offset': offset
    });
}
export const serverCheck = async (cityName: string) => {
    return await requestApi('/api/server/check', 'post', {
        'cityName': cityName
    });
}
export const updateInvoke = async (serverName: string) => {
    return await requestApi('/db/morphVpn_server/updateInvokeByName', 'post', {
        'name': serverName
    });
}