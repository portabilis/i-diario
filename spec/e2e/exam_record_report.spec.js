const { test, expect } = require('@playwright/test');

// O usuário do .env.e2e precisa ter no perfil um professor vinculado a mais de uma
// turma na escola do perfil; sem isso a troca de turma não tem o que exercitar.
const CLASSROOM = 'exam_record_report_form_classroom_id';
const DISCIPLINE = 'exam_record_report_form_discipline_id';
const STEP = 'exam_record_report_form_school_calendar_step_id';

const chosen = (page, id) => page.locator(`#s2id_${id} .select2-chosen`);

async function listOptions(page, id) {
  await page.locator(`#s2id_${id} a.select2-choice`).click();
  const labels = page.locator('#select2-drop .select2-results li .select2-result-label');
  await expect(labels.first()).toBeVisible();
  const options = (await labels.allTextContents()).map((text) => text.trim()).filter(Boolean);
  await page.keyboard.press('Escape');

  return options;
}

async function selectClassroom(page, description) {
  const disciplinesLoaded = page.waitForResponse((response) => response.url().includes('disciplin'));
  await page.locator(`#s2id_${CLASSROOM} a.select2-choice`).click();
  await page.locator('#select2-drop .select2-results li', { hasText: description }).first().click();
  await disciplinesLoaded;
}

test.describe('Registro de avaliações numéricas', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/relatorios/registro-de-avaliacoes');
    await expect(page.locator('#left-panel')).toBeVisible({ timeout: 15000 });
  });

  test('a troca de turma mantém as disciplinas restritas ao professor do perfil', async ({ page }) => {
    const initialClassroom = (await chosen(page, CLASSROOM).textContent()).trim();
    const initialDisciplines = await listOptions(page, DISCIPLINE);
    const otherClassrooms = (await listOptions(page, CLASSROOM)).filter((name) => name !== initialClassroom);

    test.skip(otherClassrooms.length === 0, 'o professor do perfil tem uma turma só nesta escola');

    await selectClassroom(page, otherClassrooms[0]);
    await selectClassroom(page, initialClassroom);

    expect(await listOptions(page, DISCIPLINE)).toEqual(initialDisciplines);
  });

  test('a troca de turma só pré-seleciona a disciplina quando há uma única opção', async ({ page }) => {
    const initialClassroom = (await chosen(page, CLASSROOM).textContent()).trim();
    const otherClassrooms = (await listOptions(page, CLASSROOM)).filter((name) => name !== initialClassroom);

    test.skip(otherClassrooms.length === 0, 'o professor do perfil tem uma turma só nesta escola');

    await selectClassroom(page, otherClassrooms[0]);
    const disciplines = await listOptions(page, DISCIPLINE);
    const expected = disciplines.length === 1 ? disciplines[0] : '';

    await expect(chosen(page, DISCIPLINE)).toHaveText(expected);
  });

  test('a troca de turma deixa a etapa em branco', async ({ page }) => {
    const initialClassroom = (await chosen(page, CLASSROOM).textContent()).trim();
    const otherClassrooms = (await listOptions(page, CLASSROOM)).filter((name) => name !== initialClassroom);

    test.skip(otherClassrooms.length === 0, 'o professor do perfil tem uma turma só nesta escola');

    await selectClassroom(page, otherClassrooms[0]);

    await expect(chosen(page, STEP)).toHaveText('');
    expect((await listOptions(page, STEP)).length).toBeGreaterThan(0);
  });
});
