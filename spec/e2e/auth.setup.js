// Autenticação compartilhada para testes E2E.
// Executa login uma única vez e salva o estado de sessão (storageState).
// Credenciais via variáveis de ambiente ou .env.e2e (carregado via dotenv no playwright.config.js).

const { test, expect } = require('@playwright/test');

const STORAGE_STATE = 'spec/e2e/.auth/user.json';

// O setup é o único teste que paga a primeira requisição fria do app (login e dashboard);
// o teto global de 30 s vale para os specs que já entram autenticados e não cabe aqui.
// 60 s para o menu lateral aparecer e o restante para o goto inicial e o storageState.
const SETUP_TIMEOUT = 90000;
const LOGIN_RENDER_TIMEOUT = 60000;

test('autenticação', async ({ page }) => {
  test.setTimeout(SETUP_TIMEOUT);

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

  // Aguarda o menu lateral aparecer (indica login completo).
  // Sem sessão o #left-panel nunca aparece, então login quebrado continua reprovando pelo expect.
  await expect(page.locator('#left-panel')).toBeVisible({ timeout: LOGIN_RENDER_TIMEOUT });

  await page.context().storageState({ path: STORAGE_STATE });
});
