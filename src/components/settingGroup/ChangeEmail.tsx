import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import MyModal from '../base/MyModal';
import RestorePage from '../../pages/RestorePage';

export default function ChangeEmail() {
    const [isOpen, setIsOpen] = useState<boolean>(false);
    const { t } = useTranslation();

    return (
        <>
            <div>
                <MyModal isOpen={isOpen} setIsOpen={setIsOpen} name={t("setting.change-password")}>
                    <RestorePage inPage={true} setIsOpen={setIsOpen}/>
                </MyModal>
            </div>

        </>
    );
}