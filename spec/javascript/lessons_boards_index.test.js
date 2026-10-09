/**
 * @jest-environment jsdom
 */

// Testes de app/assets/javascripts/views/lessons_boards/index.js.
//
// A cascata dos filtros é resolvida no servidor: a resposta remota (lessons_boards/index.js.erb)
// chama refreshFilter com as opções válidas e o valor já saneado de cada filtro. O arquivo também
// registra o aviso de falha da requisição.

const fs = require('fs');
const path = require('path');

const { loadIntoWindow, loadVendorEnvironment } = require('./support/vendor_environment');
const SELECT2_PATH = path.resolve(__dirname, '../../app/assets/javascripts/select2.js');
const FLASH_PATH = path.resolve(__dirname, '../../app/assets/javascripts/flash_messages.js');
const PAGE_PATH = path.resolve(__dirname, '../../app/assets/javascripts/views/lessons_boards/index.js');

const select2Source = fs.readFileSync(SELECT2_PATH, 'utf-8');
const pageSource = fs.readFileSync(PAGE_PATH, 'utf-8');

let select2Calls;

function stubSelect2Plugin() {
  select2Calls = [];

  window.jQuery.fn.select2 = function () {
    const args = Array.prototype.slice.call(arguments);

    select2Calls.push({ id: this.attr('id'), args: args });

    // o plugin real guarda a instância em data('select2'): é assim que a página sabe o que destruir
    if (typeof args[0] === 'object') {
      this.data('select2', { fake: true });
    } else if (args[0] === 'destroy') {
      this.removeData('select2');
    }

    return this;
  };
}

function setup(html) {
  document.body.innerHTML = '<div id="flash-messages"></div>' + html;
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
  await loadVendorEnvironment();
  loadIntoWindow(FLASH_PATH);
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

  // o handler do filterable_search_form refaz a busca a cada change: disparar aqui vira loop
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

  it('accepts a level of the cascade with no options', () => {
    window.lessonsBoardsIndex.refreshFilter('search_by_unity', [], '');

    expect(initCallFor('search_by_unity').args[0].data).toEqual([]);
    expect(window.jQuery('#search_by_unity').val()).toBe('');
  });

  it('does nothing when the field is not on the page', () => {
    expect(() => {
      window.lessonsBoardsIndex.refreshFilter('nao_existe', ELEMENTS, '4');
    }).not.toThrow();

    expect(select2Calls).toHaveLength(0);
  });
});

describe('the warning when the remote request fails', () => {
  const LISTING_PATH = '/quadro-de-aulas';

  // Sem o aviso a tela mantém a listagem anterior como se fosse o resultado do novo filtro
  beforeEach(() => {
    setup(
      `<form class="filterable_search_form" action="${LISTING_PATH}"></form>` +
      '<input id="search_by_unity" class="select2" type="hidden">'
    );
  });

  function failRequest(url, statusText) {
    window.jQuery(document).trigger('ajaxError', [
      { statusText: statusText || 'error', status: 500 },
      { url: url }
    ]);
  }

  function warning() {
    return document.getElementById('flash-messages').innerHTML;
  }

  it('warns when the listing request fails', () => {
    failRequest(`${LISTING_PATH}?search%5Bby_year%5D=2026`);

    expect(warning()).toContain('Não foi possível atualizar a lista de quadros de aula');
  });

  it('warns when the pagination request fails', () => {
    failRequest(`http://test.host${LISTING_PATH}?page=2`);

    expect(warning()).toContain('Não foi possível atualizar a lista de quadros de aula');
  });

  // O evento de erro do jQuery é disparado por qualquer requisição da página: sem o recorte por
  // endereço, uma falha nas notificações anunciaria falha da listagem.
  it('stays quiet when another request of the page fails', () => {
    failRequest('/notificacoes-do-sistema/read_all');

    expect(warning()).toBe('');
  });

  it('stays quiet when the request was aborted', () => {
    failRequest(`${LISTING_PATH}?page=2`, 'abort');

    expect(warning()).toBe('');
  });

  it('stays quiet when the request has no settings', () => {
    window.jQuery(document).trigger('ajaxError', [{ statusText: 'error' }]);

    expect(warning()).toBe('');
  });
});
