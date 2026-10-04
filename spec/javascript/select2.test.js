/**
 * @jest-environment jsdom
 */

// Testes de caracterização de app/assets/javascripts/select2.js.
//
// Esse arquivo inicializa todos os select2 do sistema, então qualquer alteração nele precisa
// provar que o comportamento observável continua igual. Os testes carregam o ambiente comum de
// plugins (spec/javascript/support/vendor_environment.js) e espionam `$.fn.select2`.

const fs = require('fs');
const path = require('path');

const { loadVendorEnvironment } = require('./support/vendor_environment');
const SCRIPT_PATH = path.resolve(__dirname, '../../app/assets/javascripts/select2.js');

const scriptSource = fs.readFileSync(SCRIPT_PATH, 'utf-8');

let select2Calls;

// Substitui o plugin real por um espião: o que importa aqui é QUAIS opções o arquivo passa.
function stubSelect2Plugin() {
  select2Calls = [];

  window.jQuery.fn.select2 = function () {
    select2Calls.push({
      id: this.attr('id'),
      args: Array.prototype.slice.call(arguments)
    });

    return this;
  };
}

function runScript(html) {
  document.body.innerHTML = html;
  stubSelect2Plugin();
  window.eval(scriptSource);
}

function initCallFor(id) {
  return select2Calls.find(function (call) {
    return call.id === id && typeof call.args[0] === 'object';
  });
}

function optionsFor(id) {
  const call = initCallFor(id);

  return call && call.args[0];
}

beforeAll(() => loadVendorEnvironment());

describe('which inputs are initialized', () => {
  beforeEach(() => {
    runScript(`
      <input id="simples" class="select2" type="hidden">
      <input id="com_outras_classes" class="select2 required" type="hidden">
      <input id="prefixado" class="select2_step" type="hidden">
      <input id="plans" class="select2_plans" type="hidden">
      <input id="remoto" class="select2_remote" type="hidden">
      <input id="remoto_composto" class="select2 select2_remote" type="hidden">
      <input id="alheio" class="outra-coisa" type="hidden">
      <select id="nao_input" class="select2"></select>
    `);
  });

  it('initializes inputs with the select2 class', () => {
    expect(initCallFor('simples')).toBeDefined();
  });

  it('initializes inputs whose class attribute starts with select2', () => {
    expect(initCallFor('prefixado')).toBeDefined();
    expect(initCallFor('plans')).toBeDefined();
  });

  it('initializes an input only once when it matches both selectors', () => {
    const calls = select2Calls.filter((call) => call.id === 'com_outras_classes');

    expect(calls).toHaveLength(1);
  });

  it('does not initialize select2_remote inputs', () => {
    expect(initCallFor('remoto')).toBeUndefined();
    expect(initCallFor('remoto_composto')).toBeUndefined();
  });

  it('does not initialize unrelated inputs', () => {
    expect(initCallFor('alheio')).toBeUndefined();
  });

  it('does not initialize non-input elements', () => {
    expect(initCallFor('nao_input')).toBeUndefined();
  });
});

describe('the options passed to select2', () => {
  const elements = [{ id: 1, name: 'ESCOLA A', text: 'ESCOLA A' }];

  beforeEach(() => {
    runScript(`
      <input id="padrao" class="select2" type="hidden"
             data-elements='${JSON.stringify(elements)}' data-multiple="false">
      <input id="multiplo" class="select2" type="hidden" data-multiple="true">
      <input id="sem_vazio" class="select2" type="hidden" data-hide-empty-element="true">
    `);
  });

  it('passes the elements from the data attribute as data', () => {
    expect(optionsFor('padrao').data).toEqual(elements);
  });

  it('passes multiple from the data attribute', () => {
    expect(optionsFor('padrao').multiple).toBe(false);
    expect(optionsFor('multiplo').multiple).toBe(true);
  });

  it('enables allowClear when hide-empty-element is absent', () => {
    expect(optionsFor('padrao').allowClear).toBe(true);
  });

  it('disables allowClear when hide-empty-element is set', () => {
    expect(optionsFor('sem_vazio').allowClear).toBe(false);
  });

  it('always uses the classic theme', () => {
    expect(optionsFor('padrao').theme).toBe('classic');
  });

  it('formats a result using the name wrapped in the result div', () => {
    const formatted = optionsFor('padrao').formatResult({ name: 'ESCOLA A' });

    expect(formatted).toBe("<div class='select2-user-result'>ESCOLA A</div>");
  });

  it('formats the selection using text when it is present', () => {
    const formatted = optionsFor('padrao').formatSelection({ name: 'nome', text: 'texto' });

    expect(formatted).toBe("<div class='select2-user-result'>texto</div>");
  });

  it('falls back to name when the selection has no text', () => {
    const formatted = optionsFor('padrao').formatSelection({ name: 'nome', text: '' });

    expect(formatted).toBe("<div class='select2-user-result'>nome</div>");
  });
});

describe('the initial value of multiple fields', () => {
  function valCallFor(id) {
    return select2Calls.find(function (call) {
      return call.id === id && call.args[0] === 'val';
    });
  }

  it('applies the parsed JSON value when the field is multiple', () => {
    runScript(`<input id="campo" class="select2" type="hidden" data-multiple="true" value="[1,2]">`);

    expect(valCallFor('campo').args[1]).toEqual([1, 2]);
  });

  it('does not apply the value when the field is not multiple', () => {
    runScript(`<input id="campo" class="select2" type="hidden" data-multiple="false" value="[1,2]">`);

    expect(valCallFor('campo')).toBeUndefined();
  });

  it('does not apply the value when the json parser is disabled', () => {
    runScript(
      `<input id="campo" class="select2" type="hidden" data-multiple="true"
              data-without-json-parser="true" value="[1,2]">`
    );

    expect(valCallFor('campo')).toBeUndefined();
  });

  it('does not apply the value when the field is empty', () => {
    runScript(`<input id="campo" class="select2" type="hidden" data-multiple="true" value="">`);

    expect(valCallFor('campo')).toBeUndefined();
  });
});

describe('the change handler of the empty element', () => {
  // O corpo do handler lê `element.val` do objeto de evento, que é sempre undefined: o ramo nunca
  // executa. O teste trava só o que é observável — em quais elementos o handler é registrado.
  it('binds a change handler on the same inputs it initializes', () => {
    runScript(`
      <input id="campo" class="select2" type="hidden">
      <input id="remoto" class="select2_remote" type="hidden">
    `);

    const $ = window.jQuery;

    expect($._data($('#campo')[0], 'events')).toHaveProperty('change');
    expect($._data($('#remoto')[0], 'events')).toBeUndefined();
  });

  it('does not clear the value on change (dead branch kept as is)', () => {
    runScript(`<input id="campo" class="select2" type="hidden" value="empty">`);

    const before = select2Calls.length;
    window.jQuery('#campo').trigger('change');

    expect(select2Calls).toHaveLength(before);
  });
});

describe('initSelect2 as a reusable entry point', () => {
  // Respostas remotas usam esta função para recriar um select2 sem duplicar a configuração.
  it('is exposed globally', () => {
    runScript('<input id="campo" class="select2" type="hidden">');

    expect(typeof window.initSelect2).toBe('function');
  });

  it('applies the same options when called directly on an element', () => {
    runScript('<input id="campo" class="select2" type="hidden" data-elements=\'[{"id":1,"name":"A","text":"A"}]\'>');

    const noReady = optionsFor('campo');
    select2Calls = [];

    window.initSelect2(window.jQuery('#campo'));
    const direto = optionsFor('campo');

    // as funções são recriadas a cada chamada: compara o comportamento, não a referência
    expect(Object.keys(direto).sort()).toEqual(Object.keys(noReady).sort());
    expect(direto.data).toEqual(noReady.data);
    expect(direto.multiple).toBe(noReady.multiple);
    expect(direto.allowClear).toBe(noReady.allowClear);
    expect(direto.theme).toBe(noReady.theme);
    expect(direto.formatResult({ name: 'X' })).toBe(noReady.formatResult({ name: 'X' }));
    expect(direto.formatSelection({ name: 'X', text: 'Y' }))
      .toBe(noReady.formatSelection({ name: 'X', text: 'Y' }));
    expect(direto.formatSelection({ name: 'X', text: '' }))
      .toBe(noReady.formatSelection({ name: 'X', text: '' }));
  });

  it('reads elements set programmatically via jQuery data', () => {
    runScript('<input id="campo" class="select2" type="hidden">');
    select2Calls = [];

    const novos = [{ id: 9, name: 'NOVA', text: 'NOVA' }];
    window.jQuery('#campo').data('elements', novos);
    window.initSelect2(window.jQuery('#campo'));

    expect(optionsFor('campo').data).toEqual(novos);
  });

  it('accepts a raw dom element as well as a jQuery object', () => {
    runScript('<input id="campo" class="select2" type="hidden">');
    select2Calls = [];

    window.initSelect2(document.getElementById('campo'));

    expect(initCallFor('campo')).toBeDefined();
  });
});
