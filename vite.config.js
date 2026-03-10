import { defineConfig } from 'vite';

export default defineConfig({
  build: {
    minify: 'esbuild', // NIEMALS 'terser' — verursacht Build-Fehler auf Netlify
    outDir: 'dist',
    rollupOptions: {
      input: {
        main: 'index.html'
      }
    }
  },
  publicDir: 'public'
});
