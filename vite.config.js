import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  // Important: this must match your GitHub repository name.
  base: '/sorting-algorithm-comparison/',
})