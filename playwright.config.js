require('dotenv').config({ path: '.env.e2e' });

const { defineConfig } = require('@playwright/test');

const STORAGE_STATE = 'spec/e2e/.auth/user.json';

module.exports = defineConfig({
  testDir: './spec/e2e',
  timeout: 30000,
  retries: 1,
  use: {
    baseURL: process.env.E2E_BASE_URL || 'http://entity.localhost:3000',
    headless: true,
    locale: 'pt-BR',
    screenshot: 'only-on-failure',
    trace: 'on-first-retry'
  },
  projects: [
    {
      name: 'setup',
      testMatch: /auth\.setup\.js/
    },
    {
      name: 'chromium',
      testIgnore: ['**/auth.setup.js'],
      use: {
        browserName: 'chromium',
        storageState: STORAGE_STATE
      },
      dependencies: ['setup']
    }
  ]
});
