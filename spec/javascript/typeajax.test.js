/**
 * @jest-environment jsdom
 */

// CVE-2025-9107 / GHSA-7ffp-7x3r-3h22
// O endpoint /alunos/search_autocomplete responde JSON, mas o termo pesquisado (`q`) volta para
// o dropdown do Bootstrap Typeahead, que insere o markup com `.html()`. A mensagem de "nada
// encontrado" montada em typeajax.js precisa escapar o termo, senão um payload como
// `<img src=x onerror=alert(1)>` executa no contexto do usuário.

const { loadVendorEnvironment } = require('./support/vendor_environment');

beforeAll(() => loadVendorEnvironment());

function setupInput() {
  document.body.innerHTML =
    '<input type="hidden">' +
    '<input id="campo" data-typeahead-url="/alunos/search_autocomplete">';

  const $ = window.jQuery;
  const $el = $('#campo');
  $el.typeajax();

  return { $, $el, instance: $el.data('typeajax') };
}

// Invoca a versao nao-debounced (do prototype) para nao depender de timers.
function fetchWith($el, instance, query, results) {
  const $ = window.jQuery;
  $el.val(query);
  $.getJSON = function () {
    const deferred = $.Deferred();
    deferred.resolve(results);
    return deferred;
  };

  const captured = [];
  const process = function (items) {
    items.forEach((item) => captured.push(JSON.parse(item)));
  };

  Object.getPrototypeOf(instance).fetch.call(instance, query, process);

  return captured;
}

describe('the "not found" message', () => {
  const payload = '"><img src=x onerror=alert(1)>';

  it('escapes the searched term instead of reflecting raw HTML', () => {
    const { $el, instance } = setupInput();
    const captured = fetchWith($el, instance, payload, []);

    const notFound = captured.find((item) => /nada foi encontrado/.test(item.value));

    expect(notFound).toBeDefined();
    expect(notFound.value).not.toContain('<img src=x onerror=alert(1)>');
    expect(notFound.value).toContain('&lt;img src=x onerror=alert(1)&gt;');
  });

  it('keeps the intended icon markup untouched', () => {
    const { $el, instance } = setupInput();
    const captured = fetchWith($el, instance, payload, []);

    const notFound = captured.find((item) => /nada foi encontrado/.test(item.value));

    expect(notFound.value).toContain('<i class="icon-thumbs-down"></i>');
  });

  it('leaves a plain term readable', () => {
    const { $el, instance } = setupInput();
    const captured = fetchWith($el, instance, 'Maria', []);

    const notFound = captured.find((item) => /nada foi encontrado/.test(item.value));

    expect(notFound.value).toContain('termo "Maria"');
  });
});

describe('the result items', () => {
  function renderResult(query, value) {
    const { $el } = setupInput();
    const typeahead = $el.data('typeahead');
    typeahead.query = query;
    typeahead.render([JSON.stringify({ id: 1, value: value })]);

    return typeahead.$menu.find('a');
  }

  it('renders an HTML payload in the student name as text', () => {
    const $link = renderResult('Ana', 'Ana <img src=x onerror=alert(1)>');

    expect($link.find('img').length).toEqual(0);
    expect($link.text()).toEqual('Ana <img src=x onerror=alert(1)>');
  });

  it('highlights the searched term', () => {
    const $link = renderResult('ana', 'Ana Paula Santana');

    expect($link.html()).toEqual('<strong>Ana</strong> Paula Sant<strong>ana</strong>');
  });

  it('highlights a term with characters that need escaping', () => {
    const $link = renderResult("d'a", "Maria D'Avila");

    expect($link.html()).toEqual("Maria <strong>D'A</strong>vila");
    expect($link.text()).toEqual("Maria D'Avila");
  });
});
