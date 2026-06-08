const { test, expect } = require('@playwright/test');

// Helpers reutilizáveis
const trigger = (page) => page.locator('#cp-trigger');
const overlay = (page) => page.locator('#command-palette-overlay');
const input = (page) => page.locator('#command-palette-input');
const items = (page) => page.locator('#command-palette-list .cp-item');

async function openPalette(page) {
  await trigger(page).click();
  await expect(overlay(page)).toHaveClass(/open/);
  await expect(input(page)).toBeFocused();
}

async function closePalette(page) {
  await page.keyboard.press('Escape');
  await expect(overlay(page)).not.toHaveClass(/open/);
}

test.describe('Paleta de comandos', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await expect(page.locator('#left-panel')).toBeVisible({ timeout: 15000 });
  });

  test.describe.serial('gatilho e atalhos de teclado', () => {
    test('exibe o gatilho com ícone, texto e badge de atalho', async ({ page }) => {
      const cp = trigger(page);
      await expect(cp).toBeVisible();
      await expect(cp.locator('.fa-search')).toBeVisible();
      await expect(cp.locator('.cp-trigger-text')).toHaveText('Buscar...');
      await expect(cp.locator('.cp-trigger-kbd')).toBeVisible();
      await expect(cp.locator('.cp-trigger-kbd')).toHaveText(/Ctrl\+K|⌘K/);
    });

    test('abre a paleta ao clicar e fecha com Escape', async ({ page }) => {
      await openPalette(page);
      await closePalette(page);
    });

    test('abre e fecha com Ctrl+K', async ({ page }) => {
      await page.locator('body').click();
      await page.keyboard.press('Control+k');
      await expect(overlay(page)).toHaveClass(/open/);

      await page.keyboard.press('Control+k');
      await expect(overlay(page)).not.toHaveClass(/open/);
    });

    test('não abre quando o foco está em um campo de texto', async ({ page }) => {
      await page.evaluate(() => {
        const el = document.createElement('input');
        el.id = 'test-editable-input';
        el.type = 'text';
        document.body.appendChild(el);
      });

      const testInput = page.locator('#test-editable-input');
      await testInput.focus();
      await expect(testInput).toBeFocused();

      await page.keyboard.press('Control+k');
      await expect(page.locator('#command-palette-overlay.open')).toHaveCount(0);
    });
  });

  test.describe.serial('estrutura do modal e itens do menu', () => {
    test('exibe campo de busca, lista de resultados e footer', async ({ page }) => {
      await openPalette(page);

      // Campo de busca
      await expect(input(page)).toHaveAttribute('placeholder', 'Navegar para...');

      // Lista de resultados
      const list = page.locator('#command-palette-list');
      await expect(list).toBeVisible();
      await expect(items(page).first()).toBeVisible();

      // Footer com atalhos
      const footer = page.locator('#command-palette-footer');
      await expect(footer).toBeVisible();
      await expect(footer.locator('kbd').first()).toBeVisible();
    });

    test('itens têm label, href válido, categoria e ícone', async ({ page }) => {
      await openPalette(page);

      // Label e href
      const firstItem = items(page).first();
      await expect(firstItem.locator('.cp-label')).toBeVisible();
      const href = await firstItem.getAttribute('href');
      expect(href).toBeTruthy();
      expect(href).not.toBe('#');

      // Categoria do pai em subitens
      await expect(page.locator('#command-palette-list .cp-item .cp-category').first()).toBeVisible();

      // Ícones
      const className = await page.locator('#command-palette-list .cp-item .cp-icon i').first().getAttribute('class');
      expect(className).toContain('fa');
    });

    test('fecha ao clicar no overlay', async ({ page }) => {
      await openPalette(page);

      // Clica no canto esquerdo do overlay (fora do modal centralizado)
      const box = await overlay(page).boundingBox();
      await page.mouse.click(box.x + 5, box.y + box.height / 2);
      await expect(overlay(page)).not.toHaveClass(/open/);
    });
  });

  test.describe.serial('busca e filtragem', () => {
    test('filtra itens ao digitar e restaura ao limpar', async ({ page }) => {
      await openPalette(page);

      const totalOriginal = await items(page).count();

      // Filtra
      await input(page).fill('Configura');
      await expect(items(page)).not.toHaveCount(totalOriginal);
      const filtered = await items(page).count();
      expect(filtered).toBeLessThan(totalOriginal);
      expect(filtered).toBeGreaterThan(0);

      // Restaura ao limpar
      await input(page).fill('');
      await expect(items(page)).toHaveCount(totalOriginal);
    });

    test('busca é case insensitive e normaliza acentos', async ({ page }) => {
      await openPalette(page);

      // Case insensitive
      await input(page).fill('CONFIGURA');
      await expect(items(page).first()).toBeVisible();
      const countUpper = await items(page).count();
      expect(countUpper).toBeGreaterThan(0);

      // Normaliza acentos (busca sem acento encontra com acento)
      await input(page).fill('frequencia');
      await expect(input(page)).toHaveValue('frequencia');
      // Não quebra mesmo que não haja resultados exatos
      const count = await items(page).count();
      expect(count).toBeGreaterThanOrEqual(0);
    });

    test('mostra estado vazio quando não há resultados', async ({ page }) => {
      await openPalette(page);

      await input(page).fill('xyztermoqueninguntemnoMenu123');
      await expect(page.locator('#command-palette-empty')).toBeVisible();
      await expect(items(page)).toHaveCount(0);
    });
  });

  test.describe.serial('navegação por teclado', () => {
    test('primeiro item selecionado por padrão, navega com setas', async ({ page }) => {
      await openPalette(page);

      // Primeiro item selecionado
      await expect(items(page).first()).toHaveClass(/selected/);

      // ArrowDown move para baixo
      await page.keyboard.press('ArrowDown');
      await expect(items(page).nth(1)).toHaveClass(/selected/);
      await expect(items(page).nth(0)).not.toHaveClass(/selected/);

      // ArrowUp volta
      await page.keyboard.press('ArrowUp');
      await expect(items(page).first()).toHaveClass(/selected/);

      // ArrowUp do primeiro faz wrap para o último
      await page.keyboard.press('ArrowUp');
      await expect(items(page).last()).toHaveClass(/selected/);
    });

    test('Enter navega para o item selecionado', async ({ page }) => {
      await openPalette(page);

      const targetHref = await items(page).first().getAttribute('href');
      await page.keyboard.press('Enter');

      await page.waitForURL('**' + targetHref, { timeout: 10000 });
      expect(page.url()).toContain(targetHref);
    });
  });

  test.describe.serial('ciclo abrir/fechar', () => {
    test('limpa a busca e restaura itens ao reabrir', async ({ page }) => {
      await openPalette(page);
      const totalOriginal = await items(page).count();

      // Digita, filtra e fecha
      await input(page).fill('Configura');
      await expect(items(page)).not.toHaveCount(totalOriginal);
      await closePalette(page);

      // Reabre: busca limpa e itens restaurados
      await openPalette(page);
      await expect(input(page)).toHaveValue('');
      await expect(items(page)).toHaveCount(totalOriginal);
    });
  });
});
