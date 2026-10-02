const { test, expect } = require('@playwright/test');

// O usuário do .env.e2e precisa ser administrador ou servidor, com uma turma no perfil que tenha
// ao menos um aluno cursando sem PEI no ano letivo, e a data de hoje precisa ser dia letivo da
// turma. O fluxo cria um PEI pela tela e o exclui no último cenário.
const INDEX_PATH = '/planos-educacionais-individualizados';
const STUDENT = 'individualized_educational_plan_student_id';
const MAX_STUDENTS_TRIED = 5;

const step = (page, number) => page.locator('#pei-wizard .steps li').nth(number - 1);
const pane = (page, number) => page.locator(`#pei-step-${number}`);
const saveStatus = (page) => page.locator('.iep-save-status-text');
const isDraftSave = (response) => response.request().method() === 'POST' &&
  response.url().includes(INDEX_PATH) && (response.request().postData() || '').includes('draft=1');

async function openNew(page) {
  await page.goto(`${INDEX_PATH}/novo`);
  await expect(page.locator('#left-panel')).toBeVisible({ timeout: 15000 });
  await expect(page.locator('#pei-wizard')).toBeVisible();
}

// Troca de etapa que precisa salvar: espera a resposta do rascunho antes de seguir.
async function goToStepSaving(page, number) {
  const saved = page.waitForResponse(isDraftSave);
  await step(page, number).click();
  await saved;
  await expect(step(page, number)).toHaveClass(/active/);
}

// Escolhe o primeiro aluno da turma que ainda não tem PEI no ano; devolve o nome dele.
async function selectStudentWithoutPlan(page) {
  for (let index = 0; index < MAX_STUDENTS_TRIED; index += 1) {
    await page.locator(`#s2id_${STUDENT} a.select2-choice`).click();
    const options = page.locator('#select2-drop .select2-results li .select2-result-label');
    await expect(options.first()).toBeVisible();
    const names = (await options.allTextContents()).map((text) => text.trim()).filter(Boolean);

    if (index >= names.length) {
      await page.keyboard.press('Escape');
      return null;
    }

    const studentData = page.waitForResponse((response) => response.url().includes('student_data'));
    await page.locator('#select2-drop .select2-results li', { hasText: names[index] }).first().click();
    const data = await (await studentData).json();

    if (!data.has_existing_plan) { return names[index]; }
  }

  return null;
}

// Digitado tecla a tecla: o campo tem máscara, que descarta no blur um valor atribuído de uma vez.
async function typeFirstReviewDate(page, date) {
  const input = page.locator('#iep-review-dates input.datepicker').first();
  await input.click();
  await input.pressSequentially(date.replace(/\D/g, ''));
  await expect(input).toHaveValue(date);
  await input.press('Tab');
}

test.describe('Plano Educacional Individualizado - salvamento de rascunho', () => {
  test.describe('CT-01: plano novo sem aluno', () => {
    test('as etapas 2 a 6 abrem travadas, com aviso e atalho para a seção 1', async ({ page }) => {
      await openNew(page);

      await step(page, 2).click();

      await expect(step(page, 2)).toHaveClass(/active/);
      await expect(page.locator('.iep-locked-notice')).toBeVisible();
      await expect(pane(page, 2).locator('textarea').first()).toBeDisabled();

      await page.locator('.iep-locked-notice .iep-go-to-identification').click();

      await expect(step(page, 1)).toHaveClass(/active/);
      await expect(page.locator('.iep-locked-notice')).toBeHidden();
    });
  });

  // Os cenários seguintes dependem do PEI criado no primeiro deles.
  test.describe.serial('fluxo do rascunho', () => {
    const reviewDate = `15/12/${new Date().getFullYear()}`;
    let planPath;
    let studentName;

    test('CT-02: sair da seção 1 cria o rascunho e a revisão já aparece nas seções 4 e 5', async ({ page }) => {
      await openNew(page);

      studentName = await selectStudentWithoutPlan(page);
      test.skip(!studentName, 'a turma do perfil não tem aluno cursando sem PEI no ano letivo');

      await typeFirstReviewDate(page, reviewDate);
      const saved = page.waitForResponse(isDraftSave);
      await page.locator('.pei-wizard-next').click();
      const response = await saved;
      test.skip(response.status() === 422, 'o rascunho foi recusado: a data de hoje pode não ser dia letivo da turma');

      await expect(step(page, 2)).toHaveClass(/active/);
      await expect(page).toHaveURL(/\/planos-educacionais-individualizados\/\d+\/editar$/);
      await expect(saveStatus(page)).toContainText('Salvo às');
      await expect(pane(page, 2).locator('textarea').first()).toBeEnabled();
      planPath = new URL(page.url()).pathname;

      await step(page, 4).click();
      await expect(pane(page, 4).locator('.iep-review-buttons button')).toHaveText(new RegExp(`1ª Revisão\\s+\\(${reviewDate}\\)`));

      await step(page, 5).click();
      await expect(pane(page, 5).locator('.iep-review-buttons button')).toHaveCount(1);
    });

    test('CT-03: a disciplina adicionada na seção 4 é salva na troca de etapa, sem duplicar', async ({ page }) => {
      test.skip(!planPath, 'o rascunho não foi criado');
      await page.goto(planPath);
      await expect(page.locator('#left-panel')).toBeVisible({ timeout: 15000 });

      await step(page, 4).click();
      const addDiscipline = pane(page, 4).locator('.iep-add-component').first();
      test.skip(!(await addDiscipline.isVisible()), 'a turma do perfil não tem disciplina vinculada');

      await addDiscipline.click();
      await page.locator('#s2id_iep-component-modal-select a.select2-choice').click();
      await page.locator('#select2-drop .select2-results li').first().click();
      await page.locator('#iep-component-modal-confirm').click();
      await pane(page, 4).locator('.iep-component-panel textarea').first().fill('Meta de longo prazo do teste');

      await goToStepSaving(page, 5);
      await expect(saveStatus(page)).toContainText('Salvo às');

      // Nada mudou desde o salvamento: voltar não envia de novo e a linha continua única.
      await step(page, 4).click();
      await expect(pane(page, 4).locator('.iep-component-pills li')).toHaveCount(1);
      await expect(pane(page, 4).locator('.iep-component-panel textarea').first()).toHaveValue('Meta de longo prazo do teste');

      // O que foi salvo continua lá depois de recarregar a página.
      await page.reload();
      await expect(page.locator('#left-panel')).toBeVisible({ timeout: 15000 });
      await step(page, 4).click();
      await expect(pane(page, 4).locator('.iep-component-panel textarea').first()).toHaveValue('Meta de longo prazo do teste');
    });

    test('CT-04: o rascunho aparece na listagem como "Em elaboração"', async ({ page }) => {
      test.skip(!planPath, 'o rascunho não foi criado');
      await page.goto(INDEX_PATH);
      await expect(page.locator('#left-panel')).toBeVisible({ timeout: 15000 });

      const row = page.locator('#resources-tbody tr', { hasText: studentName });
      await expect(row.locator('.label')).toHaveText('Em elaboração');
    });

    test('CT-05: finalizar publica a versão e a edição seguinte volta para "Em elaboração"', async ({ page }) => {
      test.skip(!planPath, 'o rascunho não foi criado');
      await page.goto(planPath);
      await expect(page.locator('#left-panel')).toBeVisible({ timeout: 15000 });

      await step(page, 6).click();
      await page.locator('.pei-wizard-finish').click();
      await page.locator('#version_name').fill('Versão do teste E2E');
      await page.locator('#iep-finalize-confirm').click();

      await expect(page).toHaveURL(new RegExp(`${INDEX_PATH}$`));
      const row = page.locator('#resources-tbody tr', { hasText: studentName });
      await expect(row.locator('.label')).toHaveText('Finalizado');

      await page.goto(planPath);
      await expect(page.locator('#left-panel')).toBeVisible({ timeout: 15000 });
      await step(page, 2).click();
      await pane(page, 2).locator('textarea').first().fill('Perfil alterado depois da finalização');
      await goToStepSaving(page, 3);

      await page.goto(INDEX_PATH);
      await expect(page.locator('#resources-tbody tr', { hasText: studentName }).locator('.label'))
        .toHaveText('Em elaboração');
    });

    test('CT-06: excluir o PEI pela listagem libera o aluno para um novo plano', async ({ page }) => {
      test.skip(!planPath, 'o rascunho não foi criado');
      await page.goto(INDEX_PATH);
      await expect(page.locator('#left-panel')).toBeVisible({ timeout: 15000 });

      const row = page.locator('#resources-tbody tr', { hasText: studentName });
      page.once('dialog', (dialog) => dialog.accept());
      await row.locator('a[data-method="delete"]').click();

      await expect(page.locator('#resources-tbody tr', { hasText: studentName })).toHaveCount(0);
    });
  });
});
