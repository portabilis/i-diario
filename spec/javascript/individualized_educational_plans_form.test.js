/**
 * @jest-environment jsdom
 */

// Testes de app/assets/javascripts/views/individualized_educational_plans/form.js no que o
// wizard do PEI faz em volta do rascunho: as etapas 2 a 6 travadas enquanto o plano não existe,
// a tela passando a se comportar como edição quando o rascunho é criado e a confirmação ao
// remover uma data de revisão que tem conteúdo nas seções 4/5.

const fs = require('fs');
const path = require('path');

const VENDOR_PATH = path.resolve(__dirname, '../../vendor/assets/javascripts');
const ASSETS_PATH = path.resolve(__dirname, '../../app/assets/javascripts');

const SOURCES = ['date.js', 'views/individualized_educational_plans/draft_autosave.js',
                 'views/individualized_educational_plans/form.js']
  .map((file) => fs.readFileSync(path.join(ASSETS_PATH, file), 'utf-8'));

const PLAN = 'individualized_educational_plan';
const LINE = `${PLAN}[iep_curricular_plannings_attributes]`;

let requests;
let modals;
let cocoonRemovals;

function loadIntoWindow(file) {
  window.eval(fs.readFileSync(file, 'utf-8'));
}

function reviewDateRow(index, id, date) {
  return `
    <div class="nested-fields" data-review-id="${id}">
      <input type="text" class="datepicker" name="${PLAN}[iep_review_dates_attributes][${index}][review_date]" value="${date}">
      <input type="hidden" name="${PLAN}[iep_review_dates_attributes][${index}][_destroy]" value="false">
      <a class="remove_fields existing" href="#">remover</a>
    </div>
  `;
}

function sectionLine(key) {
  return `
    <div class="iep-component-panel" data-key="${key}">
      <textarea name="${LINE}[${key}][long_term_goal]">Meta</textarea>
      <input type="hidden" name="${LINE}[${key}][_destroy]" value="false">
      <a class="remove_fields existing" href="#">remover</a>
    </div>
  `;
}

function reviewSection(reviewIds, lines) {
  const buttons = reviewIds.map((id, index) => `
    <button type="button" class="btn ${index === 0 ? 'btn-primary active' : 'btn-default'}" data-review-id="${id}"></button>
  `).join('');
  const panels = reviewIds.map((id) => `
    <div class="iep-review-panel" data-review-id="${id}">
      <div class="iep-component-panels" data-review-id="${id}" data-component-type="discipline">${lines[id] || ''}</div>
    </div>
  `).join('');

  return `<div class="btn-group iep-review-buttons">${buttons}</div>${panels}`;
}

function formHtml({ planId = '', studentId = '', reviewDates = reviewDateRow(0, '', ''), section4 = '' } = {}) {
  const steps = [0, 1, 2, 3, 4, 5].map((index) => `
    <li data-step="${index}" class="${index === 0 ? 'active' : ''}"><span class="badge"></span></li>
  `).join('');

  return `
    <meta name="csrf-token" content="token">
    <div id="flash-messages"></div>
    <form class="smart-form" action="/planos${planId ? `/${planId}` : ''}">
      <div id="pei-wizard" data-plan-id="${planId}" data-autosave="on" data-student-fetch="on"
           data-medical-reports-plan-id="${planId}">
        <div class="fuelux"><div class="wizard"><ul class="steps">${steps}</ul></div></div>
        <div class="alert iep-locked-notice" style="display: none;">
          <button type="button" class="iep-go-to-identification"></button>
        </div>
        <div class="alert iep-no-draft-notice" style="display: none;"></div>
        <div class="tab-content">
          <div class="tab-pane active" id="pei-step-1"><fieldset>
            <input type="text" class="datepicker iep-elaborated-at" name="${PLAN}[elaborated_at]" value="02/10/2026">
            <input type="hidden" class="select2 iep-student-select" name="${PLAN}[student_id]" value="${studentId}"
                   ${planId ? 'disabled' : ''}>
            <div id="iep-review-dates">${reviewDates}</div>
            <table><tbody id="iep-medical-reports"></tbody></table>
          </fieldset></div>
          <div class="tab-pane" id="pei-step-2"><fieldset>
            <textarea name="${PLAN}[characterization]"></textarea>
            <input type="hidden" class="select2" name="${PLAN}[autonomy_option_ids]" value="">
          </fieldset></div>
          <div class="tab-pane" id="pei-step-3"><fieldset><div id="iep-medications"></div></fieldset></div>
          <div class="tab-pane" id="pei-step-4"><fieldset>${section4}</fieldset></div>
          <div class="tab-pane" id="pei-step-5"><fieldset></fieldset></div>
          <div class="tab-pane" id="pei-step-6"><fieldset></fieldset></div>
        </div>
      </div>
      <footer>
        <span class="iep-save-status" data-saving-text="Salvando..." data-saved-text="Salvo às"
              data-unpublished-text="alterações ainda não publicadas" data-failed-text="Não foi possível salvar.">
          <span class="iep-save-status-text"></span>
          <a class="iep-save-retry" style="display: none;"></a>
        </span>
        <button type="button" class="pei-wizard-finish"></button>
        <button type="button" class="pei-wizard-next"></button>
        <button type="button" class="pei-wizard-prev"></button>
      </footer>
      <div id="iep-review-date-removal-modal"></div>
      <button type="button" id="iep-review-date-removal-confirm"></button>
    </form>
  `;
}

// select2, modal, datepicker e inputmask reais não rodam no jsdom. O stub do select2 reproduz
// só o que o form.js usa do estado do campo: habilitar/desabilitar.
function stubPlugins() {
  const $ = window.jQuery;

  $.fn.select2 = function (option, value) {
    if (option === 'enable') { this.prop('disabled', !value); }
    if (option === 'val' && value === undefined) { return this.val(); }

    return this;
  };
  $.fn.modal = function (action) {
    modals.push({ id: this.attr('id'), action: action });

    return this;
  };
  $.fn.datepicker = function () { return this; };
  $.fn.inputmask = function () { return this; };
  $.fn.tab = function () { return this; };
}

function stubGlobals() {
  window.FlashMessages = function () {
    this.success = jest.fn();
    this.error = jest.fn();
  };
  window.initSelect2 = jest.fn();
  window.Routes = new Proxy({}, { get: (_target, name) => (params) => `/${String(name)}?${window.jQuery.param(params || {})}` });
}

function stubAjax() {
  const $ = window.jQuery;

  requests = [];

  $.ajax = function (settings) {
    const deferred = $.Deferred();

    requests.push({ settings: settings, deferred: deferred });

    return deferred.promise();
  };
}

const $ = (selector) => window.jQuery(selector);
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const draftRequests = () => requests.filter((request) => /draft=1/.test(request.settings.data || ''));
const activeStep = () => $('#pei-wizard .steps li').index($('#pei-wizard .steps li.active'));
const paneLocked = (step) => $(`#pei-step-${step} > fieldset`).prop('disabled');

function setup(html) {
  // Os handlers delegados no document sobrevivem à troca do body: sem limpar, os de um teste
  // anterior responderiam aos cliques deste.
  $(document).off();
  document.body.innerHTML = html;
  modals = [];
  cocoonRemovals = [];
  stubGlobals();
  stubPlugins();
  stubAjax();

  SOURCES.forEach((source) => window.eval(source));

  // Lugar do cocoon: ele escuta o clique de remoção delegado no document.
  $(document).on('click', '.remove_fields', function () { cocoonRemovals.push(this); });
}

beforeAll(async () => {
  loadIntoWindow(path.join(VENDOR_PATH, 'jquery.js'));
  loadIntoWindow(path.join(VENDOR_PATH, 'underscore.js'));

  // deixa o `ready` do jQuery resolver; a partir daqui os callbacks rodam na hora
  await flush();
});

describe('new plan, before it is saved', () => {
  beforeEach(() => setup(formHtml()));

  it('locks sections 2 to 6 and leaves section 1 free', () => {
    expect(paneLocked(1)).toBe(false);
    expect([2, 3, 4, 5, 6].map(paneLocked)).toEqual([true, true, true, true, true]);
    expect($('#pei-step-2 input.select2').prop('disabled')).toBe(true);
  });

  it('lets the user browse the steps without a student, explaining why they are locked', () => {
    $('#pei-wizard .steps li').eq(2).trigger('click');

    expect(activeStep()).toBe(2);
    expect(draftRequests()).toHaveLength(0);
    expect($('.iep-locked-notice').css('display')).not.toBe('none');

    $('.iep-go-to-identification').trigger('click');

    expect(activeStep()).toBe(0);
    expect($('.iep-locked-notice').css('display')).toBe('none');
  });

  it('sends the finish attempt back to section 1 instead of opening the publish dialog', () => {
    const reachedDocument = jest.fn();
    $(document).on('click', '.pei-wizard-finish', reachedDocument);
    $('#pei-wizard .steps li').eq(5).trigger('click');

    $('.pei-wizard-finish').trigger('click');

    expect(reachedDocument).not.toHaveBeenCalled();
    expect(activeStep()).toBe(0);
  });

  describe('once the student and the elaboration date are informed', () => {
    beforeEach(() => {
      $('input.iep-student-select').val('31');
      $('.pei-wizard-next').trigger('click');
    });

    it('creates the draft on the first step change', () => {
      expect(draftRequests()).toHaveLength(1);
      expect(draftRequests()[0].settings.url).toBe('/planos');
      expect(activeStep()).toBe(0);
    });

    it('turns the screen into the edit screen of the created plan, without reloading', () => {
      draftRequests()[0].deferred.resolve({
        id: 9, update_url: '/planos/9', edit_url: '/planos/9/editar', form_html: '<form></form>'
      });

      expect($('form').attr('action')).toBe('/planos/9');
      expect($('form input[name="_method"]').val()).toBe('patch');
      expect($('input.iep-student-select').prop('disabled')).toBe(true);
      expect(window.location.pathname).toBe('/planos/9/editar');
      expect([2, 3, 4, 5, 6].map(paneLocked)).toEqual([false, false, false, false, false]);
      expect($('#pei-step-2 input.select2').prop('disabled')).toBe(false);
      expect(activeStep()).toBe(1);
      expect($('.iep-locked-notice').css('display')).toBe('none');
    });

    it('unlocks the sections and warns when the draft does not apply to the student', () => {
      draftRequests()[0].deferred.reject(
        { status: 422, responseJSON: { errors: ['Só será gravado ao finalizar.'], draft_unavailable: true } }, 'error'
      );

      expect($('.iep-no-draft-notice').css('display')).not.toBe('none');
      expect([2, 3, 4, 5, 6].map(paneLocked)).toEqual([false, false, false, false, false]);
      expect(activeStep()).toBe(1);
    });

    it('hides the warning, locks the sections again and retries the draft when the student changes', () => {
      draftRequests()[0].deferred.reject(
        { status: 422, responseJSON: { errors: ['Só será gravado ao finalizar.'], draft_unavailable: true } }, 'error'
      );

      $('input.iep-student-select').val('32').trigger('change');

      expect($('.iep-no-draft-notice').css('display')).toBe('none');
      expect([2, 3, 4, 5, 6].map(paneLocked)).toEqual([true, true, true, true, true]);

      $('#pei-wizard .steps li').eq(0).trigger('click');
      $('.pei-wizard-next').trigger('click');

      expect(draftRequests()).toHaveLength(2);
    });
  });
});

describe('saved plan', () => {
  const reviewDates = reviewDateRow(0, 2, '30/10/2026') + reviewDateRow(1, 3, '27/11/2026');

  beforeEach(() => {
    setup(formHtml({
      planId: '5', studentId: '31', reviewDates: reviewDates,
      section4: reviewSection([2, 3], { 2: sectionLine(7) })
    }));
  });

  it('opens with every section unlocked', () => {
    expect([2, 3, 4, 5, 6].map(paneLocked)).toEqual([false, false, false, false, false]);
  });

  it('asks before removing a review date that has content in sections 4/5', () => {
    $('#iep-review-dates .nested-fields').first().find('.remove_fields').trigger('click');

    expect(cocoonRemovals).toHaveLength(0);
    expect(modals).toContainEqual({ id: 'iep-review-date-removal-modal', action: 'show' });
  });

  it('removes the lines of the review along with the date once confirmed', () => {
    const $dateLink = $('#iep-review-dates .nested-fields').first().find('.remove_fields');
    const $lineLink = $('#pei-step-4 .iep-component-panel .remove_fields');
    $dateLink.trigger('click');

    $('#iep-review-date-removal-confirm').trigger('click');

    expect(cocoonRemovals).toEqual([$lineLink[0], $dateLink[0]]);
    expect(modals).toContainEqual({ id: 'iep-review-date-removal-modal', action: 'hide' });
  });

  it('removes a review date without content right away', () => {
    const $dateLink = $('#iep-review-dates .nested-fields').last().find('.remove_fields');

    $dateLink.trigger('click');

    expect(cocoonRemovals).toEqual([$dateLink[0]]);
    expect(modals).toHaveLength(0);
  });

  it('keeps the open review after the saved form replaces the content of sections 4/5', () => {
    $('#pei-step-4 .iep-review-buttons button').last().trigger('click');
    $(`[name="${PLAN}[characterization]"]`).val('Perfil');
    $('.pei-wizard-next').trigger('click');

    draftRequests()[0].deferred.resolve({
      id: 5,
      form_html: `<form><div id="pei-step-4"><fieldset>${reviewSection([2, 3], {})}</fieldset></div></form>`
    });

    expect($('#pei-step-4 .iep-component-panel')).toHaveLength(0);
    expect($('#pei-step-4 .iep-review-buttons button').last().hasClass('active')).toBe(true);
    expect($('#pei-step-4 .iep-review-panel').first().css('display')).toBe('none');
    expect($('#pei-step-4 .iep-review-panel').last().css('display')).not.toBe('none');
  });

  // O conteúdo das seções 4/5 é trocado a cada rascunho salvo: o clique da revisão não pode
  // depender dos botões que existiam na carga.
  it('switches the review panel on buttons that arrived after the page was loaded', () => {
    $('#pei-step-4 > fieldset').html(reviewSection([2, 3], {}));

    $('#pei-step-4 .iep-review-buttons button').last().trigger('click');

    expect($('#pei-step-4 .iep-review-buttons button').last().hasClass('active')).toBe(true);
    expect($('#pei-step-4 .iep-review-panel').first().css('display')).toBe('none');
    expect($('#pei-step-4 .iep-review-panel').last().css('display')).not.toBe('none');
  });
});
