const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  testDir: './spec/e2e',
  timeout: 30000,
  retries: 1,
  use: {
    baseURL: process.env.E2E_BASE_URL || 'http://ararangua.localhost:3000',
    headless: true,
    locale: 'pt-BR',
    screenshot: 'only-on-failure',
    trace: 'on-first-retry'
  },
  projects: [
    {
      name: 'chromium',
      use: { browserName: 'chromium' }
    }
  ]
});
