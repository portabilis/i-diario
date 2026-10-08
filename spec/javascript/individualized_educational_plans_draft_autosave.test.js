/**
 * @jest-environment jsdom
 */

// Testes de app/assets/javascripts/views/individualized_educational_plans/draft_autosave.js: a
// troca de etapa do PEI salva o rascunho antes de navegar, só envia quando algo mudou, deixa de
// fora as linhas das seções 4/5 que o usuário não alterou e troca na tela as regiões com
// registros filhos pelo formulário que o servidor devolve.

const fs = require('fs');
const path = require('path');

const VENDOR_PATH = path.resolve(__dirname, '../../vendor/assets/javascripts');
const SCRIPT_PATH = path.resolve(
  __dirname,
  '../../app/assets/javascripts/views/individualized_educational_plans/draft_autosave.js'
);

const scriptSource = fs.readFileSync(SCRIPT_PATH, 'utf-8');

const PLAN = 'individualized_educational_plan';
const LINE = `${PLAN}[iep_curricular_plannings_attributes]`;

let requests;
let options;
let autosave;

function loadIntoWindow(file) {
  window.eval(fs.readFileSync(file, 'utf-8'));
}

function linePanel(key, goal, id) {
  return `
    <div class="iep-component-panel" data-key="${key}">
      <textarea name="${LINE}[${key}][long_term_goal]">${goal}</textarea>
    </div>
    ${id ? `<input type="hidden" name="${LINE}[${key}][id]" value="${id}">` : ''}
  `;
}

function formHtml({ planId = '5', autosaveState = 'on', lines = linePanel(7, 'Meta', 7) + linePanel(8, 'Outra', 8) } = {}) {
  return `
    <meta name="csrf-token" content="token">
    <form action="/planos/${planId}">
      <input type="hidden" name="authenticity_token" value="token">
      <div id="pei-wizard" data-plan-id="${planId}" data-autosave="${autosaveState}">
        <div class="iep-save-error" style="display: none;">
          <span class="iep-save-error-text"></span>
          <a class="iep-save-retry" style="display: none;">Tentar novamente</a>
        </div>
        <textarea name="${PLAN}[characterization]">Perfil</textarea>
        <input type="text" name="${PLAN}[birth_date]" readonly value="">
        <div id="iep-review-dates"><input type="text" name="${PLAN}[iep_review_dates_attributes][0][review_date]" value=""></div>
        <div id="iep-medications"></div>
        <div id="pei-step-4"><fieldset>${lines}</fieldset></div>
        <div id="pei-step-5"><fieldset></fieldset></div>
      </div>
      <input type="text" name="version_name" value="">
      <span class="iep-save-status" data-saving-text="Salvando..." data-saved-text="Salvo às"
            data-unpublished-text="alterações ainda não publicadas" data-failed-text="Não foi possível salvar."
            data-unchanged-text="Nenhuma alteração para salvar"
            data-existing-plan-text="Abrir o PEI existente">
        <span class="iep-save-status-text"></span>
        <a class="iep-save-retry" style="display: none;">Tentar novamente</a>
      </span>
      <button type="button" class="pei-wizard-next"></button>
    </form>
  `;
}

// Formulário que o servidor devolve depois de gravar: a data de revisão já tem id e aparece
// como revisão na seção 4.
function savedFormHtml() {
  return `
    <form>
      <div id="iep-review-dates">
        <div class="nested-fields" data-review-id="2"></div>
        <input type="hidden" name="${PLAN}[iep_review_dates_attributes][0][id]" value="2">
      </div>
      <div id="iep-medications"></div>
      <div id="pei-step-4"><fieldset>
        <div class="iep-review-buttons"><button type="button" data-review-id="2">1ª Revisão</button></div>
      </fieldset></div>
      <div id="pei-step-5"><fieldset></fieldset></div>
    </form>
  `;
}

function stubAjax() {
  const $ = window.jQuery;

  requests = [];

  $.ajax = function (settings) {
    const deferred = $.Deferred();

    requests.push({ settings: settings, deferred: deferred, params: new URLSearchParams(settings.data) });

    return deferred.promise();
  };
}

const $ = (selector) => window.jQuery(selector);
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const lastRequest = () => requests[requests.length - 1];
const statusText = () => $('.iep-save-status-text').text();
const errorAlert = () => $('.iep-save-error');
const errorText = () => $('.iep-save-error-text').text();
const retryLinks = () => $('.iep-save-retry').toArray().map((link) => link.style.display !== 'none');

function saved(data) {
  lastRequest().deferred.resolve(Object.assign({ id: 5, form_html: savedFormHtml() }, data));
}

function refused(body, status = 422) {
  lastRequest().deferred.reject({ status: status, responseJSON: body }, 'error');
}

function connectionLost() {
  lastRequest().deferred.reject({ status: 0, responseText: '' }, 'error');
}

function setup(html) {
  document.body.innerHTML = html || formHtml();
  stubAjax();

  options = {
    $form: $('form'),
    $wizard: $('#pei-wizard'),
    showStep: jest.fn(),
    readyToCreate: jest.fn(() => true),
    rehydrate: jest.fn(),
    onCreated: jest.fn((data) => $('#pei-wizard').data('plan-id', data.id)),
    onUnavailable: jest.fn(),
    onAvailableAgain: jest.fn(),
    failureMessage: jest.fn(() => null)
  };

  window.eval(scriptSource);
  autosave = window.IepDraftAutosave(options);
  autosave.markBaseline();
}

beforeAll(async () => {
  loadIntoWindow(path.join(VENDOR_PATH, 'jquery.js'));
  loadIntoWindow(path.join(VENDOR_PATH, 'underscore.js'));

  // deixa o `ready` do jQuery resolver; a partir daqui os callbacks rodam na hora
  await flush();
});

describe('when nothing changed since the form was loaded', () => {
  beforeEach(() => setup());

  it('goes to the step without sending anything', () => {
    autosave.saveThenGo(2);

    expect(requests).toHaveLength(0);
    expect(options.showStep).toHaveBeenCalledWith(2);
  });

  // O prefill do i-Educar preenche os campos de exibição depois da carga da página.
  it('does not take a read-only field filled later as a change', () => {
    $(`[name="${PLAN}[birth_date]"]`).val('01/02/2015');

    autosave.saveThenGo(2);

    expect(requests).toHaveLength(0);
  });
});

describe('when the form changed', () => {
  beforeEach(() => {
    setup();
    $(`[name="${PLAN}[characterization]"]`).val('Perfil novo');
  });

  it('sends the form as a draft to the form action and only then changes the step', () => {
    autosave.saveThenGo(2);

    expect(lastRequest().settings.url).toBe('/planos/5');
    expect(lastRequest().settings.type).toBe('POST');
    expect(lastRequest().params.get('draft')).toBe('1');
    expect(lastRequest().params.get(`${PLAN}[characterization]`)).toBe('Perfil novo');
    expect(lastRequest().params.has('version_name')).toBe(false);
    expect(options.showStep).not.toHaveBeenCalled();
    expect(statusText()).toBe('Salvando...');

    saved();

    expect(options.showStep).toHaveBeenCalledWith(2);
    expect(statusText()).toMatch(/^Salvo às \d{2}:\d{2} - alterações ainda não publicadas$/);
    expect(errorAlert().css('display')).toBe('none');
  });

  it('ignores another navigation while the save is in flight', () => {
    autosave.saveThenGo(2);
    autosave.saveThenGo(3);

    expect(requests).toHaveLength(1);
    expect($('.pei-wizard-next').prop('disabled')).toBe(true);

    saved();

    expect($('.pei-wizard-next').prop('disabled')).toBe(false);
    expect(options.showStep).toHaveBeenCalledTimes(1);
  });

  it('leaves out the section 4/5 lines the user did not change, with their ids', () => {
    $(`[name="${LINE}[8][long_term_goal]"]`).val('Outra meta');

    autosave.saveThenGo(2);

    expect(lastRequest().params.has(`${LINE}[7][long_term_goal]`)).toBe(false);
    expect(lastRequest().params.has(`${LINE}[7][id]`)).toBe(false);
    expect(lastRequest().params.get(`${LINE}[8][long_term_goal]`)).toBe('Outra meta');
    expect(lastRequest().params.get(`${LINE}[8][id]`)).toBe('8');
  });

  it('always sends a line added after the form was loaded', () => {
    $('#pei-step-4 fieldset').append(linePanel('new_component_1', 'Nova'));

    autosave.saveThenGo(2);

    expect(lastRequest().params.get(`${LINE}[new_component_1][long_term_goal]`)).toBe('Nova');
  });

  it('replaces the regions with nested records by the form the server returns and rehydrates them', () => {
    autosave.saveThenGo(3);
    saved();

    expect($('#iep-review-dates .nested-fields').data('review-id')).toBe(2);
    expect($('#pei-step-4 .iep-review-buttons button')).toHaveLength(1);
    expect($('#pei-step-4 .iep-component-panel')).toHaveLength(0);
    // o que não é região trocada fica como o usuário deixou
    expect($(`[name="${PLAN}[characterization]"]`).val()).toBe('Perfil novo');
    expect(options.rehydrate).toHaveBeenCalledTimes(4);
  });

  // O servidor descarta o que o usuário não pode editar e responde sucesso mesmo assim.
  it('does not announce a save when the server reports that nothing changed', () => {
    autosave.saveThenGo(2);
    saved({ changed: false });

    expect(options.showStep).toHaveBeenCalledWith(2);
    expect(statusText()).toBe('Nenhuma alteração para salvar');
    expect(errorAlert().css('display')).toBe('none');
  });

  it('takes the saved state as the new baseline', () => {
    autosave.saveThenGo(3);
    saved();

    autosave.saveThenGo(4);

    expect(requests).toHaveLength(1);
    expect(options.showStep).toHaveBeenLastCalledWith(4);
  });

  // O rodapé pode estar fora da tela: o motivo vai num alerta no topo da etapa.
  it('stays on the step and shows the reasons in the alert above it when the server refuses the data', () => {
    const scrollIntoView = jest.fn();
    errorAlert()[0].scrollIntoView = scrollIntoView;

    autosave.saveThenGo(2);
    refused({ errors: ['Informe ao menos um medicamento com nome'] });

    expect(options.showStep).not.toHaveBeenCalled();
    expect(errorAlert().css('display')).not.toBe('none');
    expect(errorText()).toBe('Informe ao menos um medicamento com nome');
    expect(scrollIntoView).toHaveBeenCalled();
    expect(statusText()).toBe('Não foi possível salvar.');
    expect($('.iep-save-status').hasClass('iep-save-failed')).toBe(true);
    expect(retryLinks()).toEqual([false, false]);
  });

  it('hides the alert once the corrected data is saved', () => {
    autosave.saveThenGo(2);
    refused({ errors: ['Informe ao menos um medicamento com nome'] });

    autosave.saveThenGo(2);
    saved();

    expect(errorAlert().css('display')).toBe('none');
    expect($('.iep-save-status').hasClass('iep-save-failed')).toBe(false);
    expect(options.showStep).toHaveBeenCalledWith(2);
  });

  it('drops the alert when the user undoes the refused change instead of fixing it', () => {
    autosave.saveThenGo(2);
    refused({ errors: ['Informe ao menos um medicamento com nome'] });
    $(`[name="${PLAN}[characterization]"]`).val('Perfil');

    autosave.saveThenGo(2);

    expect(requests).toHaveLength(1);
    expect(errorAlert().css('display')).toBe('none');
    expect(statusText()).toBe('');
    expect(options.showStep).toHaveBeenCalledWith(2);
  });

  it('keeps what is on the screen, changes the step and offers to retry when the request fails', () => {
    autosave.saveThenGo(2);
    connectionLost();

    expect(options.showStep).toHaveBeenCalledWith(2);
    expect($(`[name="${PLAN}[characterization]"]`).val()).toBe('Perfil novo');
    expect(statusText()).toBe('Não foi possível salvar.');
    expect(errorText()).toBe('Não foi possível salvar.');
    expect(retryLinks()).toEqual([true, true]);

    $('.iep-save-error .iep-save-retry').trigger('click');
    saved();

    expect(requests).toHaveLength(2);
    expect(statusText()).toMatch(/^Salvo às/);
    expect(retryLinks()).toEqual([false, false]);
  });

  it('shows the session message when the failure is an expired session', () => {
    options.failureMessage.mockReturnValue('Sua sessão expirou.');

    autosave.saveThenGo(2);
    lastRequest().deferred.reject({ status: 401, responseText: '' }, 'error');

    expect(errorText()).toBe('Sua sessão expirou.');
  });

  it('leaves the unchanged lines out of the native submit too', () => {
    autosave.disableUnchangedLines();

    expect($(`[name="${LINE}[7][long_term_goal]"]`).prop('disabled')).toBe(true);
    expect($(`[name="${LINE}[7][id]"]`).prop('disabled')).toBe(true);
    expect($(`[name="${PLAN}[characterization]"]`).prop('disabled')).toBe(false);
  });
});

describe('when the server tells which field was refused', () => {
  const MEDICATION = `${PLAN}[iep_medications_attributes]`;
  const group = (name) => $(`[name="${name}"]`).closest('.control-group');

  function fieldsHtml() {
    return `
      <form action="/planos/5">
        <div id="pei-wizard" data-plan-id="5" data-autosave="on">
          <div class="iep-save-error" style="display: none;"><span class="iep-save-error-text"></span></div>
          <div class="tab-content">
            <div class="tab-pane" id="pei-step-1">
              <div class="control-group"><input type="text" name="${PLAN}[elaborated_at]" value="02/10/2026"></div>
            </div>
            <div class="tab-pane active" id="pei-step-3">
              <div id="iep-medications">
                <div class="control-group"><input type="text" name="${MEDICATION}[0][name]" value="Salvo"></div>
                <input type="hidden" name="${MEDICATION}[0][id]" value="12">
                <div class="control-group"><input type="text" name="${MEDICATION}[1][name]" value=""></div>
                <input type="hidden" name="${MEDICATION}[1][_destroy]" value="1">
                <div class="control-group"><input type="text" name="${MEDICATION}[171][name]" value=""></div>
                <div class="control-group"><input type="text" name="${MEDICATION}[171][dosage]" value=""></div>
              </div>
            </div>
          </div>
        </div>
        <span class="iep-save-status" data-failed-text="Não foi possível salvar."><span class="iep-save-status-text"></span></span>
      </form>
    `;
  }

  function refuseWith(fieldErrors) {
    $(`[name="${MEDICATION}[171][dosage]"]`).val('10 mg');
    autosave.saveThenGo(3);
    refused({ errors: ['Recusado'], field_errors: fieldErrors });
  }

  beforeEach(() => setup(fieldsHtml()));

  it('marks the new, empty row of the nested field, with the message next to it', () => {
    refuseWith([{ association: 'iep_medications', id: null, attribute: 'name', message: 'não pode ficar em branco' }]);

    expect(group(`${MEDICATION}[171][name]`).hasClass('error')).toBe(true);
    expect(group(`${MEDICATION}[171][name]`).find('.help-inline').text()).toBe('não pode ficar em branco');
    // linha salva e linha removida não são a linha recusada
    expect(group(`${MEDICATION}[0][name]`).hasClass('error')).toBe(false);
    expect(group(`${MEDICATION}[1][name]`).hasClass('error')).toBe(false);
    expect(options.showStep).not.toHaveBeenCalled();
  });

  it('marks the saved nested record by its id', () => {
    refuseWith([{ association: 'iep_medications', id: 12, attribute: 'name', message: 'não pode ficar em branco' }]);

    expect(group(`${MEDICATION}[0][name]`).hasClass('error')).toBe(true);
    expect(group(`${MEDICATION}[171][name]`).hasClass('error')).toBe(false);
  });

  it('marks a field of the plan itself and opens its step when it is another one', () => {
    refuseWith([{ attribute: 'elaborated_at', message: 'não pode ficar em branco' }]);

    expect(group(`${PLAN}[elaborated_at]`).hasClass('error')).toBe(true);
    expect(options.showStep).toHaveBeenCalledWith(0);
  });

  // A data de elaboração já mostra o aviso de calendário da própria tela quando o dia não é letivo.
  it('does not add a second message to a field that already shows one', () => {
    group(`${PLAN}[elaborated_at]`).append('<span class="help-inline error">deve ser um dia letivo</span>');

    refuseWith([{ attribute: 'elaborated_at', message: 'deve ser um dia letivo' }]);

    expect(group(`${PLAN}[elaborated_at]`).hasClass('error')).toBe(true);
    expect(group(`${PLAN}[elaborated_at]`).find('.help-inline')).toHaveLength(1);
  });

  it('clears the mark when the user edits the field', () => {
    refuseWith([{ association: 'iep_medications', id: null, attribute: 'name', message: 'não pode ficar em branco' }]);

    $(`[name="${MEDICATION}[171][name]"]`).val('Metilfenidato').trigger('input');

    expect(group(`${MEDICATION}[171][name]`).hasClass('error')).toBe(false);
    expect(group(`${MEDICATION}[171][name]`).find('.help-inline')).toHaveLength(0);
  });

  it('clears the marks on the next save attempt', () => {
    refuseWith([{ association: 'iep_medications', id: null, attribute: 'name', message: 'não pode ficar em branco' }]);

    autosave.saveThenGo(3);

    expect($('.control-group.error')).toHaveLength(0);
  });
});

describe('while the plan does not exist yet', () => {
  beforeEach(() => setup(formHtml({ planId: '', lines: '' })));

  it('is locked and only navigates while there is no student and elaboration date', () => {
    options.readyToCreate.mockReturnValue(false);

    autosave.saveThenGo(1);

    expect(autosave.isLocked()).toBe(true);
    expect(requests).toHaveLength(0);
    expect(options.showStep).toHaveBeenCalledWith(1);
  });

  it('creates the plan on the first navigation and hands the new plan to the form', () => {
    autosave.saveThenGo(1);
    saved({ id: 9, update_url: '/planos/9', edit_url: '/planos/9/editar' });

    expect(options.onCreated).toHaveBeenCalledWith(expect.objectContaining({ id: 9, update_url: '/planos/9' }));
    expect(autosave.isLocked()).toBe(false);
    expect(options.showStep).toHaveBeenCalledWith(1);
  });

  it('stays on section 1 with a link to the plan the student already has', () => {
    autosave.saveThenGo(1);
    refused({ errors: ['Este aluno já possui um PEI neste ano letivo.'], existing_plan_url: '/planos/3/editar' });

    expect(options.showStep).not.toHaveBeenCalled();
    expect($('.iep-save-error-text a').attr('href')).toBe('/planos/3/editar');
    expect($('.iep-save-error-text a').text().trim()).toBe('Abrir o PEI existente');
    expect($('.iep-save-error-text a').hasClass('btn')).toBe(true);
  });

  // As demais etapas continuam travadas: navegar levaria a uma tela sem nada para preencher.
  it('stays on section 1 when the request to create fails', () => {
    autosave.saveThenGo(1);
    connectionLost();

    expect(options.showStep).not.toHaveBeenCalled();
    expect(autosave.isLocked()).toBe(true);
  });

  it('stops saving and unlocks when the draft does not apply to the student', () => {
    autosave.saveThenGo(1);
    refused({ errors: ['Só será gravado ao finalizar.'], draft_unavailable: true });

    expect(options.onUnavailable).toHaveBeenCalled();
    expect(autosave.isLocked()).toBe(false);
    expect(options.showStep).toHaveBeenCalledWith(1);

    autosave.saveThenGo(2);

    expect(requests).toHaveLength(1);
    expect(options.showStep).toHaveBeenLastCalledWith(2);
  });

  // A recusa era do aluno anterior: com outro aluno o rascunho volta a ser tentado.
  it('saves again, locked until then, once the student changes after the draft was refused', () => {
    autosave.saveThenGo(1);
    refused({ errors: ['Só será gravado ao finalizar.'], draft_unavailable: true });

    autosave.studentChanged();

    expect(options.onAvailableAgain).toHaveBeenCalled();
    expect(autosave.isLocked()).toBe(true);

    autosave.saveThenGo(2);

    expect(requests).toHaveLength(2);
  });

  it('ignores a student change when the draft was not refused', () => {
    autosave.studentChanged();

    expect(options.onAvailableAgain).not.toHaveBeenCalled();
  });

  it('starts without saving when the form already says the draft does not apply', () => {
    setup(formHtml({ planId: '', lines: '' }).replace('data-autosave="on"', 'data-autosave="on" data-draft-unavailable="on"'));

    autosave.saveThenGo(1);

    expect(requests).toHaveLength(0);
    expect(autosave.isLocked()).toBe(false);
    expect(options.showStep).toHaveBeenCalledWith(1);
  });
});

describe('with the autosave off (read-only screens)', () => {
  beforeEach(() => setup(formHtml({ autosaveState: 'off' })));

  it('only navigates, even with the form changed', () => {
    $(`[name="${PLAN}[characterization]"]`).val('Perfil novo');

    autosave.saveThenGo(2);

    expect(requests).toHaveLength(0);
    expect(autosave.isLocked()).toBe(false);
    expect(options.showStep).toHaveBeenCalledWith(2);
  });
});
