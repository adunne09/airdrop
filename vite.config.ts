import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import * as path from 'path'
import svgLoader from 'vite-svg-loader'

import * as packagejson from './package.json'
process.env.VITE_APP_AUTHOR = packagejson.author

const cp = require('child_process')

let version
try {
  version = cp.execSync('git rev-parse --short HEAD').toString().trim()
  if (cp.execSync('git status --porcelain').toString().trim().length > 0) {
    version = `${version} (dirty)`
  }
  process.env.VITE_APP_VERSION = version
} catch {
  // no-op
}

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue(), svgLoader()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
})
