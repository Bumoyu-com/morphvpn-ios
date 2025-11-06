import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')

  return {
    plugins: [react()],
    // base: mode === 'production' ? '/dist/' : '/',
    // 禁用log
    // esbuild: {
    //   drop: process.env.NODE_ENV === 'production' ? ['console', 'debugger'] : []
    // },

    base: './',
    build: {
      outDir: mode === 'development' ? 'dist-dev' : 'dist',
      rollupOptions: {
        output: {
          manualChunks: mode === 'production' ? {
            vendor: ['react', 'react-dom', 'react-router-dom']
          } : undefined
        }
      }
    },
    server: {
      port: 3000,
      open: true
    },
    define: {
      // 把变量注入为全局常量，代码里可直接用
      __API_BASE__: JSON.stringify(env.VITE_API_BASE),
      __ENV__: JSON.stringify(env.VITE_ENV),
    }
  }
})