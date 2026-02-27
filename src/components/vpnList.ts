export interface vpnListType {
    code: string,
    city: string,
    country: string,
    testIp: string,
    testUrl: string
}
export interface vpnOriginType {
    cityName: string,
    createdAt: string,
    creating: number,
    id: string,
    types: string,
    updatedAt: string,
}

export const vpnList: vpnListType[] = [
    {
        "code": "nrt",
        "city": "Tokyo",
        "country": "Japan",
        "testIp": "108.61.201.151",
        "testUrl": "https://hnd-jp-ping.vultr.com/"
    },
    {
        "code": "icn",
        "city": "Seoul",
        "country": "South Korea",
        "testIp": "141.164.34.61",
        "testUrl": "https://sel-kor-ping.vultr.com/"
    },
    {
        "code": "lhr",
        "city": "London",
        "country": "United Kingdom",
        "testIp": "108.61.196.101",
        "testUrl": "https://lon-gb-ping.vultr.com/"
    },
    {
        "code": "man",
        "city": "Manchester",
        "country": "United Kingdom",
        "testIp": "64.176.178.136",
        "testUrl": "https://man-uk-ping.vultr.com/"
    },
    {
        "code": "ewr",
        "city": "New York",
        "country": "United States",
        "testIp": "108.61.149.182",
        "testUrl": "https://nj-us-ping.vultr.com/"
    },
    {
        "code": "lax",
        "city": "Los Angeles",
        "country": "United States",
        "testIp": "108.61.219.200",
        "testUrl": "https://lax-ca-us-ping.vultr.com/"
    },
    {
        "code": "sjc",
        "city": "Silicon Valley",
        "country": "United States",
        "testIp": "104.156.230.107",
        "testUrl": "https://sjo-ca-us-ping.vultr.com/"
    },
    {
        "code": "jnb",
        "city": "Johannesburg",
        "country": "South Africa",
        "testIp": "139.84.226.78",
        "testUrl": "https://jnb-za-ping.vultr.com/"
    },
    {
        "code": "ams",
        "city": "Amsterdam",
        "country": "Netherlands",
        "testIp": "108.61.198.102",
        "testUrl": "https://ams-nl-ping.vultr.com/"
    },
    {
        "code": "cdg",
        "city": "Paris",
        "country": "France",
        "testIp": "108.61.209.127",
        "testUrl": "https://par-fr-ping.vultr.com/"
    },
    {
        "code": "atl",
        "city": "Atlanta",
        "country": "United States",
        "testIp": "108.61.193.166",
        "testUrl": "https://ga-us-ping.vultr.com/"
    },
    {
        "code": "mex",
        "city": "Mexico City",
        "country": "Mexico",
        "testIp": "216.238.66.16",
        "testUrl": "https://mex-mx-ping.vultr.com/"
    },
    {
        "code": "yto",
        "city": "Toronto",
        "country": "Canada",
        "testIp": "149.248.50.81",
        "testUrl": "https://tor-ca-ping.vultr.com/"
    },
    {
        "code": "syd",
        "city": "Sydney",
        "country": "Australia",
        "testIp": "108.61.212.117",
        "testUrl": "https://syd-au-ping.vultr.com/"
    },
    {
        "code": "scl",
        "city": "Santiago",
        "country": "Chile",
        "testIp": "64.176.2.7",
        "testUrl": "https://scl-cl-ping.vultr.com/"
    },
    {
        "code": "mad",
        "city": "Madrid",
        "country": "Spain",
        "testIp": "208.76.222.30",
        "testUrl": "https://mad-es-ping.vultr.com/"
    },
    {
        "code": "waw",
        "city": "Warsaw",
        "country": "Poland",
        "testIp": "70.34.242.24",
        "testUrl": "https://waw-pl-ping.vultr.com/"
    },
    {
        "code": "dfw",
        "city": "Dallas",
        "country": "United States",
        "testIp": "108.61.224.175",
        "testUrl": "https://tx-us-ping.vultr.com/"
    },
    {
        "code": "sea",
        "city": "Seattle",
        "country": "United States",
        "testIp": "108.61.194.105",
        "testUrl": "https://wa-us-ping.vultr.com/"
    },
    {
        "code": "mel",
        "city": "Melbourne",
        "country": "Australia",
        "testIp": "67.219.110.24",
        "testUrl": "https://mel-au-ping.vultr.com/"
    },
    {
        "code": "bom",
        "city": "Mumbai",
        "country": "India",
        "testIp": "65.20.66.100",
        "testUrl": "https://bom-in-ping.vultr.com/"
    },
    {
        "code": "tlv",
        "city": "Tel Aviv",
        "country": "Israel",
        "testIp": "64.176.162.16",
        "testUrl": "https://tlv-il-ping.vultr.com/"
    },
    {
        "code": "blr",
        "city": "Bangalore",
        "country": "India",
        "testIp": "139.84.130.100",
        "testUrl": "https://blr-in-ping.vultr.com/"
    },
    {
        "code": "del",
        "city": "Delhi NCR",
        "country": "India",
        "testIp": "139.84.162.104",
        "testUrl": "https://del-in-ping.vultr.com/"
    },
    {
        "code": "fra",
        "city": "Frankfurt",
        "country": "Germany",
        "testIp": "108.61.210.117",
        "testUrl": "https://fra-de-ping.vultr.com/"
    },
    {
        "code": "sto",
        "city": "Stockholm",
        "country": "Sweden",
        "testIp": "70.34.194.86",
        "testUrl": "https://sto-se-ping.vultr.com/"
    },
    {
        "code": "mia",
        "city": "Miami",
        "country": "United States",
        "testIp": "104.156.244.232",
        "testUrl": "https://fl-us-ping.vultr.com/"
    },
    {
        "code": "itm",
        "city": "Osaka",
        "country": "Japan",
        "testIp": "64.176.34.94",
        "testUrl": "https://osk-jp-ping.vultr.com/"
    },
    {
        "code": "ord",
        "city": "Chicago",
        "country": "United States",
        "testIp": "107.191.51.12",
        "testUrl": "https://il-us-ping.vultr.com/"
    },
    {
        "code": "sgp",
        "city": "Singapore",
        "country": "Singapore",
        "testIp": "45.32.100.168",
        "testUrl": "https://sgp-ping.vultr.com/"
    },
    {
        "code": "admin_hk",
        "city": "Hong Kong",
        "country": "China",
        "testIp": "",
        "testUrl": ""
    }
]

export const extractVpnList = (arr: vpnOriginType[],isAdmin?: boolean): vpnListType[] => {
    let result: vpnListType[] = []
    arr.forEach(item => {
        const findItem = vpnList.find(vpn => vpn.code === item.cityName);
        if (findItem){
            if(findItem.code.includes('admin')){
                if(isAdmin) result.push(findItem);
            }
            else result.push(findItem);
        }
        else console.warn('该城市不存在==>', item.cityName);
    })
    return result
}
