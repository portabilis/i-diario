/**
 * @jest-environment jsdom
 */

// Testes de caracterização de app/assets/javascripts/views/avaliations/multiple_classrooms.js.
//
// Descrição e Peso são escondidos por updateFieldsBasedOnTestSetting (cálculo por soma) e exibidos
// por updateFieldsBaseOnTestSettingTest (tipo de avaliação quebrável). Como os dois dependem de
// resposta HTTP, os testes controlam quando cada resposta chega: se as duas forem disparadas em
// paralelo, quem decide a tela é a última a responder.

const fs = require('fs');
const path = require('path');

const VENDOR_PATH = path.resolve(__dirname, '../../vendor/assets/javascripts');
const SCRIPT_PATH = path.resolve(
  __dirname,
  '../../app/assets/javascripts/views/avaliations/multiple_classrooms.js'
);

const scriptSource = fs.readFileSync(SCRIPT_PATH, 'utf-8');

const TEST_SETTING_ID = '10';
const TEST_SETTING_TEST_ID = '14';
const SETTING_URL = '/configuracoes-de-avaliacoes-numericas/' + TEST_SETTING_ID;
const TEST_URL = '/test_setting_tests/' + TEST_SETTING_TEST_ID;

let requests;

function loadIntoWindow(file) {
  window.eval(fs.readFileSync(file, 'utf-8'));
}

function formHtml(testSettingTestId) {
  return `
    <section class="avaliation_multiple_creator_form_test_setting_id">
      <input id="avaliation_multiple_creator_form_test_setting_id" type="hidden" value="${TEST_SETTING_ID}">
    </section>
    <section class="avaliation_multiple_creator_form_unity_id">
      <input id="avaliation_multiple_creator_form_unity_id" type="hidden" value="1">
    </section>
    <section class="avaliation_multiple_creator_form_discipline_id">
      <input id="avaliation_multiple_creator_form_discipline_id" type="hidden" value="5">
    </section>
    <section class="avaliation_multiple_creator_form_test_setting_test_id">
      <input id="avaliation_multiple_creator_form_test_setting_test_id" type="hidden" value="${testSettingTestId}">
    </section>
    <section class="avaliation_multiple_creator_form_description">
      <input id="avaliation_multiple_creator_form_description" type="text">
    </section>
    <section class="avaliation_multiple_creator_form_weight">
      <input id="avaliation_multiple_creator_form_weight" type="text">
    </section>
    <table><tbody id="avaliations"></tbody></table>
  `;
}

// O select2 real não roda no jsdom; o que o arquivo usa dele é `select2('val')`, que devolve o
// valor do input hidden.
function stubPlugins() {
  const $ = window.jQuery;

  $.fn.select2 = function (option) {
    return option === 'val' ? this.val() : this;
  };
  $.fn.inputmask = function () {
    return this;
  };
  $.fn.tooltip = function () {
    return this;
  };
}

function stubGetJSON() {
  const $ = window.jQuery;

  requests = {};

  $.getJSON = function (url) {
    const deferred = $.Deferred();

    requests[url] = deferred;

    return deferred.promise();
  };
}

function runScript(testSettingTestId) {
  document.body.innerHTML = formHtml(testSettingTestId);
  stubPlugins();
  stubGetJSON();
  window.eval(scriptSource);
}

function respondWithCalculationType(averageCalculationType) {
  requests[SETTING_URL].resolve({
    test_setting: {
      exam_setting_type: 'by_school_term',
      average_calculation_type: averageCalculationType,
      number_of_decimal_places: 1
    }
  });
}

function displayOf(selector) {
  return document.querySelector(selector).style.display;
}

beforeAll(async () => {
  loadIntoWindow(path.join(VENDOR_PATH, 'jquery.js'));
  loadIntoWindow(path.join(VENDOR_PATH, 'underscore.js'));

  // deixa o `ready` do jQuery resolver; a partir daqui os callbacks rodam na hora
  await new Promise((resolve) => setTimeout(resolve, 0));
});

describe('description and weight visibility on load', () => {
  beforeEach(() => {
    runScript(TEST_SETTING_TEST_ID);
  });

  it('asks for the test type only after knowing the calculation type', () => {
    expect(requests[SETTING_URL]).toBeDefined();
    expect(requests[TEST_URL]).toBeUndefined();

    respondWithCalculationType('sum');

    expect(requests[TEST_URL]).toBeDefined();
  });

  it('shows description and weight when the test type allows breaking up', () => {
    respondWithCalculationType('sum');
    requests[TEST_URL].resolve({ allow_break_up: true });

    expect(displayOf('.avaliation_multiple_creator_form_description')).not.toBe('none');
    expect(displayOf('.avaliation_multiple_creator_form_weight')).not.toBe('none');
  });

  it('keeps description and weight hidden when the test type does not allow breaking up', () => {
    respondWithCalculationType('sum');
    requests[TEST_URL].resolve({ allow_break_up: false });

    expect(displayOf('.avaliation_multiple_creator_form_description')).toBe('none');
    expect(displayOf('.avaliation_multiple_creator_form_weight')).toBe('none');
  });

  it('shows description and weight without asking for the test type when the calculation is arithmetic and sum', () => {
    respondWithCalculationType('arithmetic_and_sum');

    expect(requests[TEST_URL]).toBeUndefined();
    expect(displayOf('.avaliation_multiple_creator_form_description')).not.toBe('none');
    expect(displayOf('.avaliation_multiple_creator_form_weight')).not.toBe('none');
  });
});

describe('when no test type is selected', () => {
  beforeEach(() => {
    runScript('');
  });

  it('hides description and weight', () => {
    respondWithCalculationType('sum');

    expect(requests[TEST_URL]).toBeUndefined();
    expect(displayOf('.avaliation_multiple_creator_form_description')).toBe('none');
    expect(displayOf('.avaliation_multiple_creator_form_weight')).toBe('none');
  });
});
