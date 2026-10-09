/**
 * @jest-environment jsdom
 */

// Testes de app/assets/javascripts/views/descriptive_exams/form.js: o tipo de avaliação decide
// quais campos a tela mostra e quais valores ela mantém. Tipos por disciplina mantêm a disciplina
// escolhida; tipos anuais escondem a etapa e limpam o valor dela.

const fs = require('fs');
const path = require('path');

const VENDOR_PATH = path.resolve(__dirname, '../../vendor/assets/javascripts');
const SCRIPT_PATH = path.resolve(
  __dirname,
  '../../app/assets/javascripts/views/descriptive_exams/form.js'
);

const scriptSource = fs.readFileSync(SCRIPT_PATH, 'utf-8');

const BY_STEP_AND_DISCIPLINE = '2';
const BY_YEAR_AND_DISCIPLINE = '5';

function loadIntoWindow(file) {
  window.eval(fs.readFileSync(file, 'utf-8'));
}

function formHtml(opinionType) {
  return `
    <form>
      <input id="descriptive_exam_classroom_id" type="hidden" value="10">
      <input id="descriptive_exam_opinion_type" type="hidden" value="${opinionType}"
             data-elements='[{"id":"empty"},{"id":"${opinionType}"}]'>
      <div class="hidden" data-descriptive-exam-discipline-container>
        <input id="descriptive_exam_discipline_id" type="hidden" value="100">
      </div>
      <div class="hidden" data-descriptive-exam-step-container>
        <input id="descriptive_exam_step_id" type="hidden" value="1">
      </div>
      <a id="view-btn" class="disabled"></a>
    </form>
  `;
}

// O select2 real não roda no jsdom; o stub só cobre as chamadas que a tela faz.
function stubPlugins() {
  const $ = window.jQuery;

  $.fn.select2 = function (option, value) {
    if (option === 'val' && value === undefined) return this.val();
    if (option === 'val') this.val(value);

    return this;
  };
}

function stubGlobals() {
  window.Routes = {
    find_descriptive_exams_pt_br_path: (params) => `/find?${window.jQuery.param(params || {})}`
  };
}

function stubAjax() {
  const $ = window.jQuery;

  $.ajax = function () {
    return $.Deferred().promise();
  };
}

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const $ = (selector) => window.jQuery(selector);

async function loadForm(opinionType) {
  document.body.innerHTML = formHtml(opinionType);
  stubGlobals();
  stubPlugins();
  stubAjax();
  window.eval(scriptSource);
  await flush();
}

beforeAll(async () => {
  loadIntoWindow(path.join(VENDOR_PATH, 'jquery.js'));
  loadIntoWindow(path.join(VENDOR_PATH, 'underscore.js'));

  // deixa o `ready` do jQuery resolver; a partir daqui os callbacks rodam na hora
  await flush();
});

describe('opinion type by step and discipline', () => {
  beforeEach(() => loadForm(BY_STEP_AND_DISCIPLINE));

  it('shows the discipline and the step', () => {
    expect($('[data-descriptive-exam-discipline-container]').hasClass('hidden')).toBe(false);
    expect($('[data-descriptive-exam-step-container]').hasClass('hidden')).toBe(false);
  });

  it('keeps the selected discipline and step', () => {
    expect($('#descriptive_exam_discipline_id').val()).toBe('100');
    expect($('#descriptive_exam_step_id').val()).toBe('1');
  });
});

describe('opinion type by year and discipline', () => {
  beforeEach(() => loadForm(BY_YEAR_AND_DISCIPLINE));

  it('shows the discipline and hides the step', () => {
    expect($('[data-descriptive-exam-discipline-container]').hasClass('hidden')).toBe(false);
    expect($('[data-descriptive-exam-step-container]').hasClass('hidden')).toBe(true);
  });

  it('keeps the selected discipline and clears the step', () => {
    expect($('#descriptive_exam_discipline_id').val()).toBe('100');
    expect($('#descriptive_exam_step_id').val()).toBe('');
  });
});
