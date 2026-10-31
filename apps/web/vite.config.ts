/// <reference types="vitest/config" />
import { copyFileSync, mkdirSync } from 'node:fs';
import { isAbsolute, join } from 'node:path';
import { fileURLToPath, URL } from 'node:url';
import tailwindcss from '@tailwindcss/vite';
import react from '@vitejs/plugin-react';
import { defineConfig, type Plugin } from 'vite';
import { writeSpaFallback } from './src/shared/seo/spa';

function copyRepoGuides(): Plugin {
  const webRoot = fileURLToPath(new URL('.', import.meta.url));
  const repoRoot = fileURLToPath(new URL('../..', import.meta.url));
  const outDir = `${webRoot}public/guides`;
  const files = [
    ['docs/EDITOR.md', 'editor.md'],
    ['docs/PLUGINS.md', 'plugins.md'],
    ['docs/E2E-TESTPLAN.md', 'testing.md'],
  ] as const;

  function copy() {
    mkdirSync(outDir, { recursive: true });
    for (const [from, to] of files) {
      copyFileSync(`${repoRoot}${from}`, `${outDir}/${to}`);
    }
  }

  return {
    name: 'copy-repo-guides',
    buildStart: copy,
    configureServer: copy,
  };
}

function spaFallback(): Plugin {
  let outDir = fileURLToPath(new URL('./dist', import.meta.url));
  return {
    name: 'spa-fallback',
    apply: 'build',
    configResolved(config) {
      outDir = isAbsolute(config.build.outDir)
        ? config.build.outDir
        : join(config.root, config.build.outDir);
    },
    closeBundle() {
      writeSpaFallback(outDir);
    },
  };
}

export default defineConfig({
  appType: 'spa',
  plugins: [react(), tailwindcss(), copyRepoGuides(), spaFallback()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  test: {
    environment: 'jsdom',
    include: ['src/**/*.test.ts', 'src/**/*.test.tsx'],
    globals: true,
    setupFiles: ['./src/test-setup.ts'],
  },
});
