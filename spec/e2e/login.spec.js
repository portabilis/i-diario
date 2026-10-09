const { test, expect } = require('@playwright/test');

// Testa o login como funcionalidade, partindo de sessão limpa.
// Ignora o storageState do setup — senão o teste já começaria autenticado.
test.use({ storageState: { cookies: [], origins: [] } });

const credentials = (page) => page.locator('#user_credentials');
const password = (page) => page.locator('#user_password');
const submit = (page) => page.locator('#btn-login');

async function signIn(page) {
  await credentials(page).fill(process.env.E2E_USER_EMAIL || 'admin@example.com');
  await password(page).fill(process.env.E2E_USER_PASSWORD);
  await submit(page).click();
}

test.describe('Login', () => {
  test.beforeAll(() => {
    // Falha cedo e com mensagem clara — senha truncada por '#' no .env.e2e
    // consumiria tentativas do contador de bloqueio da conta.
    if (!process.env.E2E_USER_PASSWORD) {
      throw new Error(
        'E2E_USER_PASSWORD não definida. Configure no .env.e2e ou via variável de ambiente.'
      );
    }
  });

  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test.describe('CT-01: exibição da tela de login', () => {
    test('redireciona visitante não autenticado para a tela de login', async ({ page }) => {
      await expect(page).toHaveURL(/\/usuarios\/logar/);
      await expect(credentials(page)).toBeVisible();
      await expect(password(page)).toBeVisible();
      await expect(submit(page)).toBeVisible();
    });
  });

  test.describe('CT-02: login com credenciais válidas', () => {
    test('autentica e exibe a tela inicial', async ({ page }) => {
      await signIn(page);

      await expect(page.locator('#left-panel')).toBeVisible({ timeout: 15000 });
      await expect(credentials(page)).toHaveCount(0);
    });
  });

  test.describe('CT-03: menu lateral após autenticar', () => {
    test('exibe itens de navegação e o link de sair', async ({ page }) => {
      await signIn(page);
      await expect(page.locator('#left-panel')).toBeVisible({ timeout: 15000 });

      await expect(page.locator('#left-panel a[href="/user_students"]')).toBeVisible();
      // "Sair" fica num dropdown fechado do cabeçalho — presente no DOM, não visível
      await expect(page.locator('#header a[href="/usuarios/sair"]')).toHaveCount(1);
    });
  });

  test.describe('CT-04: rota interna exige autenticação', () => {
    test('redireciona para o login ao acessar rota interna sem sessão', async ({ page }) => {
      await page.goto('/ocorrencias-disciplinares');

      await expect(page).toHaveURL(/\/usuarios\/logar/);
      await expect(credentials(page)).toBeVisible();
    });
  });
});
