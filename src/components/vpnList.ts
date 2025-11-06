export interface vpnListType {
    code: string,
    city: string,
    country: string
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
        "country": "Japan"
    },
    {
        "code": "icn",
        "city": "Seoul",
        "country": "South Korea"
    },
    {
        "code": "lhr",
        "city": "London",
        "country": "United Kingdom"
    },
    {
        "code": "man",
        "city": "Manchester",
        "country": "United Kingdom"
    },
    {
        "code": "ewr",
        "city": "New York",
        "country": "United States"
    },
    {
        "code": "lax",
        "city": "Los Angeles",
        "country": "United States"
    },
    {
        "code": "sjc",
        "city": "Silicon Valley",
        "country": "United States"
    },
    {
        "code": "jnb",
        "city": "Johannesburg",
        "country": "South Africa"
    },
    {
        "code": "ams",
        "city": "Amsterdam",
        "country": "Netherlands"
    },
    {
        "code": "cdg",
        "city": "Paris",
        "country": "France"
    },
    {
        "code": "atl",
        "city": "Atlanta",
        "country": "United States"
    },
    {
        "code": "mex",
        "city": "Mexico City",
        "country": "Mexico"
    },
    {
        "code": "yto",
        "city": "Toronto",
        "country": "Canada"
    },
    {
        "code": "syd",
        "city": "Sydney",
        "country": "Australia"
    },
    {
        "code": "scl",
        "city": "Santiago",
        "country": "Chile"
    },
    {
        "code": "mad",
        "city": "Madrid",
        "country": "Spain"
    },
    {
        "code": "waw",
        "city": "Warsaw",
        "country": "Poland"
    },
    {
        "code": "dfw",
        "city": "Dallas",
        "country": "United States"
    },
    {
        "code": "sea",
        "city": "Seattle",
        "country": "United States"
    },
    {
        "code": "mel",
        "city": "Melbourne",
        "country": "Australia"
    },
    {
        "code": "bom",
        "city": "Mumbai",
        "country": "India"
    },
    {
        "code": "tlv",
        "city": "Tel Aviv",
        "country": "Israel"
    },
    {
        "code": "blr",
        "city": "Bangalore",
        "country": "India"
    },
    {
        "code": "del",
        "city": "Delhi NCR",
        "country": "India"
    },
    {
        "code": "fra",
        "city": "Frankfurt",
        "country": "Germany"
    },
    {
        "code": "sto",
        "city": "Stockholm",
        "country": "Sweden"
    },
    {
        "code": "mia",
        "city": "Miami",
        "country": "United States"
    },
    {
        "code": "itm",
        "city": "Osaka",
        "country": "Japan"
    },
    {
        "code": "ord",
        "city": "Chicago",
        "country": "United States"
    },
    {
        "code": "sgp",
        "city": "Singapore",
        "country": "Singapore"
    },
    {
        "code": "admin_hk",
        "city": "Hong Kong",
        "country": "China"
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
