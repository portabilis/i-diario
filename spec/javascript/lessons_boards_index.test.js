/**
 * @jest-environment jsdom
 */

// Testes de app/assets/javascripts/views/lessons_boards/index.js.
//
// A cascata dos filtros do quadro de aulas é resolvida no servidor: a resposta remota
// (lessons_boards/index.js.erb) chama refreshFilter com as opções válidas e o valor já saneado de
// cada filtro. Esta função é o único JS da tela.

const fs = require('fs');
const path = require('path');

const VENDOR_PATH = path.resolve(__dirname, '../../vendor/assets/javascripts');
const SELECT2_PATH = path.resolve(__dirname, '../../app/assets/javascripts/select2.js');
const PAGE_PATH = path.resolve(__dirname, '../../app/assets/javascripts/views/lessons_boards/index.js');

const select2Source = fs.readFileSync(SELECT2_PATH, 'utf-8');
const pageSource = fs.readFileSync(PAGE_PATH, 'utf-8');

let select2Calls;

function loadIntoWindow(file) {
  window.eval(fs.readFileSync(file, 'utf-8'));
}

function stubSelect2Plugin() {
  select2Calls = [];

  window.jQuery.fn.select2 = function () {
    const args = Array.prototype.slice.call(arguments);

    select2Calls.push({ id: this.attr('id'), args: args });

    // o plugin real guarda a instância em data('select2'); é assim que a página sabe se há o que destruir
    if (typeof args[0] === 'object') {
      this.data('select2', { fake: true });
    } else if (args[0] === 'destroy') {
      this.removeData('select2');
    }

    return this;
  };
}

function setup(html) {
  document.body.innerHTML = html;
  stubSelect2Plugin();
  window.eval(select2Source);
  window.eval(pageSource);
}

function initCallFor(id) {
  return select2Calls.find((call) => call.id === id && typeof call.args[0] === 'object');
}

const ELEMENTS = [
  { id: 'empty', name: '<option></option>', text: '' },
  { id: 4, name: 'ESCOLA A', text: 'ESCOLA A' }
];

beforeAll(async () => {
  loadIntoWindow(path.join(VENDOR_PATH, 'jquery.js'));
  loadIntoWindow(path.join(VENDOR_PATH, 'underscore.js'));

  await new Promise((resolve) => setTimeout(resolve, 0));
});

describe('lessonsBoardsIndex.refreshFilter', () => {
  beforeEach(() => {
    setup('<input id="search_by_unity" class="select2" type="hidden">');
    select2Calls = [];
  });

  it('reinitializes the field with the options sent by the server', () => {
    window.lessonsBoardsIndex.refreshFilter('search_by_unity', ELEMENTS, '4');

    expect(initCallFor('search_by_unity').args[0].data).toEqual(ELEMENTS);
  });

  it('applies the value sanitized by the server', () => {
    window.lessonsBoardsIndex.refreshFilter('search_by_unity', ELEMENTS, '4');

    expect(window.jQuery('#search_by_unity').val()).toBe('4');
  });

  it('clears the field when the server discarded the value', () => {
    window.jQuery('#search_by_unity').val('99');

    window.lessonsBoardsIndex.refreshFilter('search_by_unity', ELEMENTS, '');

    expect(window.jQuery('#search_by_unity').val()).toBe('');
  });

  it('destroys the previous instance before reinitializing', () => {
    window.jQuery('#search_by_unity').data('select2', { fake: true });

    window.lessonsBoardsIndex.refreshFilter('search_by_unity', ELEMENTS, '4');

    expect(select2Calls[0].args).toEqual(['destroy']);
    expect(select2Calls[1].args[0]).toHaveProperty('data');
  });

  it('does not destroy when the field was never initialized', () => {
    window.jQuery('#search_by_unity').removeData('select2');

    window.lessonsBoardsIndex.refreshFilter('search_by_unity', ELEMENTS, '4');

    expect(select2Calls.map((call) => call.args[0])).not.toContain('destroy');
  });

  // o handler global do filterable_search_form refaz a busca a cada change: disparar aqui é loop
  it('does not trigger change when applying the value', () => {
    const onChange = jest.fn();
    window.jQuery('#search_by_unity').on('change', onChange);

    window.lessonsBoardsIndex.refreshFilter('search_by_unity', ELEMENTS, '4');

    expect(onChange).not.toHaveBeenCalled();
  });

  it('uses the same select2 configuration as the rest of the system', () => {
    window.lessonsBoardsIndex.refreshFilter('search_by_unity', ELEMENTS, '4');

    const options = initCallFor('search_by_unity').args[0];

    expect(options.theme).toBe('classic');
    expect(options.allowClear).toBe(true);
    expect(options.formatResult({ name: 'ESCOLA A' }))
      .toBe("<div class='select2-user-result'>ESCOLA A</div>");
  });

  it('does nothing when the field is not on the page', () => {
    expect(() => {
      window.lessonsBoardsIndex.refreshFilter('nao_existe', ELEMENTS, '4');
    }).not.toThrow();

    expect(select2Calls).toHaveLength(0);
  });
});
