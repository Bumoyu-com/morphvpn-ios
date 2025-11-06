/// <reference types="vite/client" />
interface ImportMetaEnv {
    readonly VITE_API_BASE: string
    readonly VITE_ENV: string
}

interface ImportMeta {
    readonly env: ImportMetaEnv
}

/* 这里声明 define 注入的全局常量 */
declare const __API_BASE__: string
declare const __ENV__: string