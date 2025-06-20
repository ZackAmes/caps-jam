import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'
import fs from 'fs'

// https://vite.dev/config/
export default defineConfig({
  plugins: [svelte()],
  server: {
    https: {
      key: fs.readFileSync('./localhost+2-key.pem'),
      cert: fs.readFileSync('./localhost+2.pem'),
    },
    port: 5173,
    host: true,
  },
})
