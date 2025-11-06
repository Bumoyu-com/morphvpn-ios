import React from 'react'
import { Select } from 'antd';
import { countries } from './phoneCodeCountries'


//分类排序app组件
export default function PhoneCode(prop) {
    const { Option } = Select;
    // let { t } = useTranslation()
    const t = (v) => {
        return v
    }
    //切换排序时
    function onChange(value) {
        prop.setareaCode(value)
        console.log('change:', value);
        console.log(value.split(' ')[0]);
    }

    function onSearch(val) {
        console.log('search:', val);
    }

    return (
        <>
            <div className={prop.single ? 'phoneCode-outer-single' : 'phoneCode-outer'}>
                {prop.single ? '' : <div className='phoneCode-text'>{t('Area Code') + "："} </div>}
                <Select
                    className='phoneCode-select'
                    style={{ width: prop.single ? '95%' : '70%' }}
                    showSearch
                    placeholder={prop.single ? "Select" : "*Select a code"}
                    optionFilterProp="children"
                    onChange={onChange}
                    onSearch={onSearch}
                    dropdownStyle={{ background: '#242424', borderRadius: '6px' }}
                    getPopupContainer={triggerNode => triggerNode.parentElement}
                    filterOption={(input, option) =>
                        option.children.toLowerCase().indexOf(input.toLowerCase()) >= 0
                    }
                >
                    {countries.map((ele, ind) => {
                        return <Option key={ind} value={ele.dialCode + ' ' + ele.name}>{ele.dialCode + ' ' + ele.name}</Option>
                    })}
                </Select>
            </div>
        </>

    );
}
