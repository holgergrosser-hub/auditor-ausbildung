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
  // Static files from /public get copied to /dist (e.g. sitemap.xml, robots.txt, _redirects)
  publicDir: 'public'
});
