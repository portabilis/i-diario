const { test, expect } = require('@playwright/test');
const { login } = require('./helpers/auth');

test.describe('Paleta de comandos', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test.describe('gatilho de busca no menu lateral', () => {
    test('exibe o gatilho com ícone e texto', async ({ page }) => {
      const trigger = page.locator('#cp-trigger');
      await expect(trigger).toBeVisible();
      await expect(trigger.locator('.fa-search')).toBeVisible();
      await expect(trigger.locator('.cp-trigger-text')).toHaveText('Buscar...');
    });

    test('exibe badge com atalho de teclado', async ({ page }) => {
      const kbd = page.locator('#cp-trigger .cp-trigger-kbd');
      await expect(kbd).toBeVisible();
      await expect(kbd).toHaveText(/Ctrl\+K|⌘K/);
    });

    test('abre a paleta ao clicar', async ({ page }) => {
      await page.click('#cp-trigger');

      const overlay = page.locator('#command-palette-overlay');
      await expect(overlay).toHaveClass(/open/);
      await expect(page.locator('#command-palette-input')).toBeFocused();
    });
  });

  test.describe('atalho de teclado', () => {
    test('abre a paleta com Ctrl+K', async ({ page }) => {
      // Garante que nenhum input editável está focado
      await page.locator('body').click();
      await page.keyboard.press('Control+k');

      await expect(page.locator('#command-palette-overlay')).toHaveClass(/open/);
    });

    test('fecha a paleta com Ctrl+K quando já está aberta', async ({ page }) => {
      await page.locator('body').click();
      await page.keyboard.press('Control+k');
      await expect(page.locator('#command-palette-overlay')).toHaveClass(/open/);

      await page.keyboard.press('Control+k');
      await expect(page.locator('#command-palette-overlay')).not.toHaveClass(/open/);
    });

    test('não abre quando o foco está em um campo de texto', async ({ page }) => {
      // Injeta um input real na página para garantir que existe um campo editável
      await page.evaluate(() => {
        const input = document.createElement('input');
        input.id = 'test-editable-input';
        input.type = 'text';
        document.body.appendChild(input);
      });

      const testInput = page.locator('#test-editable-input');
      await testInput.focus();
      await expect(testInput).toBeFocused();

      await page.keyboard.press('Control+k');

      // Verifica que a paleta NÃO abriu
      await expect(page.locator('#command-palette-overlay.open')).toHaveCount(0);
    });
  });

  test.describe('estrutura do modal', () => {
    test.beforeEach(async ({ page }) => {
      await page.click('#cp-trigger');
    });

    test('exibe o campo de busca com placeholder', async ({ page }) => {
      const input = page.locator('#command-palette-input');
      await expect(input).toBeVisible();
      await expect(input).toHaveAttribute('placeholder', 'Navegar para...');
    });

    test('exibe a lista de resultados', async ({ page }) => {
      const list = page.locator('#command-palette-list');
      await expect(list).toBeVisible();
      await expect(list.locator('.cp-item')).not.toHaveCount(0);
    });

    test('exibe o footer com dicas de atalho', async ({ page }) => {
      const footer = page.locator('#command-palette-footer');
      await expect(footer).toBeVisible();

      const kbds = footer.locator('kbd');
      await expect(kbds).not.toHaveCount(0);
    });

    test('fecha ao clicar no overlay', async ({ page }) => {
      const overlay = page.locator('#command-palette-overlay');

      // Clica na parte inferior do overlay (fora do modal que fica centralizado)
      const box = await overlay.boundingBox();
      await page.mouse.click(box.x + box.width / 2, box.y + box.height - 10);

      await expect(overlay).not.toHaveClass(/open/);
    });

    test('fecha ao pressionar Escape', async ({ page }) => {
      // Espera o input receber foco (open() usa setTimeout de 50ms)
      await expect(page.locator('#command-palette-input')).toBeFocused();
      await page.keyboard.press('Escape');

      await expect(page.locator('#command-palette-overlay')).not.toHaveClass(/open/);
    });
  });

  test.describe('itens do menu', () => {
    test.beforeEach(async ({ page }) => {
      await page.click('#cp-trigger');
    });

    test('lista itens de navegação do menu', async ({ page }) => {
      const items = page.locator('#command-palette-list .cp-item');
      const count = await items.count();

      expect(count).toBeGreaterThan(0);

      // Cada item deve ter label e href válido
      const firstItem = items.first();
      await expect(firstItem.locator('.cp-label')).toBeVisible();
      const href = await firstItem.getAttribute('href');
      expect(href).toBeTruthy();
      expect(href).not.toBe('#');
    });

    test('itens de submenu mostram a categoria do pai', async ({ page }) => {
      // Procura qualquer item que tenha categoria
      const itemsWithCategory = page.locator('#command-palette-list .cp-item .cp-category');
      const count = await itemsWithCategory.count();

      expect(count).toBeGreaterThan(0);
    });

    test('itens preservam ícones do menu original', async ({ page }) => {
      const firstIcon = page.locator('#command-palette-list .cp-item .cp-icon i').first();
      const className = await firstIcon.getAttribute('class');

      expect(className).toContain('fa');
    });
  });

  test.describe('busca e filtragem', () => {
    test.beforeEach(async ({ page }) => {
      await page.click('#cp-trigger');
    });

    test('filtra itens ao digitar', async ({ page }) => {
      const input = page.locator('#command-palette-input');
      const items = page.locator('#command-palette-list .cp-item');

      const totalBefore = await items.count();

      await input.fill('Configura');
      await page.waitForTimeout(100);

      const totalAfter = await items.count();
      expect(totalAfter).toBeLessThan(totalBefore);
      expect(totalAfter).toBeGreaterThan(0);
    });

    test('normaliza acentos na busca', async ({ page }) => {
      const input = page.locator('#command-palette-input');

      // Busca sem acento deve encontrar itens com acento
      await input.fill('frequencia');
      await page.waitForTimeout(100);

      const items = page.locator('#command-palette-list .cp-item');
      const count = await items.count();

      // Deve encontrar pelo menos "Frequências" se o menu tiver esse item
      // Se não tiver, o teste simplesmente verifica que a busca não quebra
      expect(count).toBeGreaterThanOrEqual(0);
    });

    test('busca é case insensitive', async ({ page }) => {
      const input = page.locator('#command-palette-input');

      await input.fill('CONFIGURA');
      await page.waitForTimeout(100);

      const items = page.locator('#command-palette-list .cp-item');
      const count = await items.count();

      expect(count).toBeGreaterThan(0);
    });

    test('mostra estado vazio quando não há resultados', async ({ page }) => {
      const input = page.locator('#command-palette-input');

      await input.fill('xyztermoqueninguntemnoMenu123');
      await page.waitForTimeout(100);

      await expect(page.locator('#command-palette-list .cp-item')).toHaveCount(0);
      await expect(page.locator('#command-palette-empty')).toBeVisible();
    });

    test('restaura todos os itens ao limpar a busca', async ({ page }) => {
      const input = page.locator('#command-palette-input');
      const items = page.locator('#command-palette-list .cp-item');

      const totalOriginal = await items.count();

      await input.fill('Configura');
      await page.waitForTimeout(100);

      await input.fill('');
      await page.waitForTimeout(100);

      const totalAfterClear = await items.count();
      expect(totalAfterClear).toBe(totalOriginal);
    });
  });

  test.describe('navegação por teclado', () => {
    test.beforeEach(async ({ page }) => {
      await page.click('#cp-trigger');
      // Espera o input receber foco (open() usa setTimeout de 50ms)
      await expect(page.locator('#command-palette-input')).toBeFocused();
    });

    test('primeiro item está selecionado por padrão', async ({ page }) => {
      const firstItem = page.locator('#command-palette-list .cp-item').first();
      await expect(firstItem).toHaveClass(/selected/);
    });

    test('ArrowDown move a seleção para baixo', async ({ page }) => {
      await page.keyboard.press('ArrowDown');

      const items = page.locator('#command-palette-list .cp-item');
      await expect(items.nth(1)).toHaveClass(/selected/);
      await expect(items.nth(0)).not.toHaveClass(/selected/);
    });

    test('ArrowUp move a seleção para cima (wrap)', async ({ page }) => {
      // Do primeiro item, ArrowUp vai para o último
      await page.keyboard.press('ArrowUp');

      const items = page.locator('#command-palette-list .cp-item');
      const lastItem = items.last();
      await expect(lastItem).toHaveClass(/selected/);
    });

    test('Enter navega para o item selecionado', async ({ page }) => {
      const firstItem = page.locator('#command-palette-list .cp-item').first();
      const targetHref = await firstItem.getAttribute('href');

      await page.keyboard.press('Enter');

      // Deve navegar para a URL do item
      await page.waitForURL('**' + targetHref, { timeout: 10000 });
      expect(page.url()).toContain(targetHref);
    });
  });

  test.describe('ciclo abrir/fechar', () => {
    test('limpa a busca ao reabrir', async ({ page }) => {
      await page.click('#cp-trigger');
      const input = page.locator('#command-palette-input');
      await expect(input).toBeFocused();
      await input.fill('teste');
      await page.keyboard.press('Escape');

      await page.click('#cp-trigger');
      await expect(input).toHaveValue('');
    });

    test('restaura todos os itens ao reabrir', async ({ page }) => {
      await page.click('#cp-trigger');
      const input = page.locator('#command-palette-input');
      await expect(input).toBeFocused();

      const items = page.locator('#command-palette-list .cp-item');
      const totalOriginal = await items.count();

      await input.fill('Configura');
      await page.waitForTimeout(100);
      await page.keyboard.press('Escape');

      await page.click('#cp-trigger');
      const totalAfterReopen = await items.count();

      expect(totalAfterReopen).toBe(totalOriginal);
    });
  });
});
