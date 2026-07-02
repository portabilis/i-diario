// Autenticação compartilhada para testes E2E.
// Executa login uma única vez e salva o estado de sessão (storageState).
// Credenciais via variáveis de ambiente ou .env.e2e (carregado via dotenv no playwright.config.js).

const { test, expect } = require('@playwright/test');

const STORAGE_STATE = 'spec/e2e/.auth/user.json';

test('autenticação', async ({ page }) => {
  const email = process.env.E2E_USER_EMAIL || 'admin@example.com';
  const password = process.env.E2E_USER_PASSWORD;

  if (!password) {
    throw new Error(
      'E2E_USER_PASSWORD não definida. Configure no .env.e2e ou via variável de ambiente.'
    );
  }

  await page.goto('/');

  await page.locator('#user_credentials').fill(email);
  await page.locator('#user_password').fill(password);
  await page.locator('#btn-login').click();

  // Aguarda o menu lateral aparecer (indica login completo)
  await expect(page.locator('#left-panel')).toBeVisible({ timeout: 15000 });

  await page.context().storageState({ path: STORAGE_STATE });
});
