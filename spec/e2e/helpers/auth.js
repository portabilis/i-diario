// Autenticação reutilizável para testes E2E.
// Credenciais via variáveis de ambiente: E2E_USER_EMAIL e E2E_USER_PASSWORD.

async function login(page, {
  email = process.env.E2E_USER_EMAIL || 'admin@portabilis.com.br',
  password = process.env.E2E_USER_PASSWORD
} = {}) {
  if (!password) {
    throw new Error(
      'E2E_USER_PASSWORD não definida. Execute: E2E_USER_PASSWORD=<senha> npx playwright test'
    );
  }
  await page.goto('/');

  // Preenche o formulário de login
  await page.locator('#user_credentials').fill(email);
  await page.locator('#user_password').fill(password);
  await page.locator('#btn-login').click();

  // Aguarda o menu lateral aparecer (indica login completo)
  await page.locator('#left-panel').waitFor({ state: 'visible', timeout: 15000 });
}

module.exports = { login };
