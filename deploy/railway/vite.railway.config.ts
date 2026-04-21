/**
 * Railway / Docker-only Vite config. Keeps the `crimson` submodule untouched.
 * Build with: vite build --config vite.railway.config.ts
 *
 * Env (build-time):
 *   VITE_API_PROXY_TARGET — dev proxy target (default http://localhost:8422)
 *   VITE_API_BASE — API path prefix baked into the bundle (default /api/v2)
 */
import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const apiBase = env.VITE_API_BASE || '/api/v2'
  const proxyTarget =
    env.VITE_API_PROXY_TARGET || 'http://localhost:8422'

  return {
    plugins: [
      react(),
      {
        name: 'railway-inject-api-base',
        transform(code, id) {
          const normalized = id.replace(/\\/g, '/')
          if (!normalized.endsWith('src/api/client.ts')) return null
          const needle = "const BASE = '/api/v2'"
          if (!code.includes(needle)) return null
          return code.replace(
            needle,
            `const BASE = ${JSON.stringify(apiBase)}`,
          )
        },
      },
    ],
    server: {
      port: 5173,
      proxy: {
        '/api': { target: proxyTarget, changeOrigin: true },
      },
    },
    build: {
      outDir: 'dist',
    },
  }
})
