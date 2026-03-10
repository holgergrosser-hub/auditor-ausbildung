import { defineConfig } from 'vite';

export default defineConfig({
  build: {
    minify: 'esbuild', // NIEMALS 'terser'
    outDir: 'dist',
    rollupOptions: {
      input: {
        main: 'index.html'
      }
    }
  },
  publicDir: false  // Bilder liegen im Root, werden von Vite direkt kopiert
});
