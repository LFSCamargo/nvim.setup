import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: './scripts/tests',
  testMatch: 'web-browser.spec.mjs',
  use: { baseURL: 'http://127.0.0.1:4173', colorScheme: 'dark' },
  webServer: {
    command: 'pnpm --filter web exec vite --host 127.0.0.1 --port 4173',
    url: 'http://127.0.0.1:4173',
    reuseExistingServer: false,
  },
});
