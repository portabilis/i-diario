/**
 * @jest-environment jsdom
 */

// Testes de app/assets/javascripts/views/ieducar_api_exam_posting/last_step_absence_warning.js.
//
// Os links de envio são `link_to ... method: :post`: o jquery_ujs os trata num handler delegado
// em `document`. O script intercepta só os links marcados com data-last-step-absence-warning,
// abre a modal e, na confirmação, dispara o POST pelo mesmo caminho do ujs ($.rails.handleMethod).

const fs = require('fs');
const path = require('path');

const VENDOR_PATH = path.resolve(__dirname, '../../vendor/assets/javascripts');
const PAGE_PATH = path.resolve(
  __dirname,
  '../../app/assets/javascripts/views/ieducar_api_exam_posting/last_step_absence_warning.js'
);

const pageSource = fs.readFileSync(PAGE_PATH, 'utf-8');

const MODAL_HTML =
  '<div class="modal fade" id="last-step-absence-warning-modal">' +
  '  <button type="button" id="last-step-absence-warning-continue">Continuar envio</button>' +
  '</div>';

// href="#" evita o jsdom tentar navegar quando o clique não é interceptado
const LINKS_HTML =
  '<a id="warned" href="#" data-method="post" data-last-step-absence-warning="true">Enviar</a>' +
  '<a id="plain" href="#" data-method="post">Enviar</a>';

let modalCalls;
let ujsHandler;
let $;

function loadIntoWindow(file) {
  window.eval(fs.readFileSync(file, 'utf-8'));
}

function stubModalPlugin() {
  modalCalls = [];

  $.fn.modal = function (action) {
    modalCalls.push(action);

    return this;
  };
}

// Simula o handler delegado do jquery_ujs para links com data-method.
function stubUjs() {
  ujsHandler = jest.fn();
  $.rails = { handleMethod: jest.fn() };
  $(document).off('click.ujs-stub').on('click.ujs-stub', 'a[data-method]', ujsHandler);
}

async function setup(html) {
  document.body.innerHTML = html;
  stubModalPlugin();
  stubUjs();
  window.eval(pageSource);

  // o script registra os handlers no ready do jQuery
  await new Promise((resolve) => setTimeout(resolve, 0));
}

function click(id) {
  const element = document.getElementById(id);

  return element.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
}

beforeAll(async () => {
  loadIntoWindow(path.join(VENDOR_PATH, 'jquery.js'));
  $ = window.jQuery;

  await new Promise((resolve) => setTimeout(resolve, 0));
});

describe('last step absence warning', () => {
  describe('when the page renders the modal', () => {
    beforeEach(async () => {
      await setup(LINKS_HTML + MODAL_HTML);
    });

    it('opens the modal instead of posting when the flagged link is clicked', () => {
      const defaultAllowed = click('warned');

      expect(defaultAllowed).toBe(false);
      expect(modalCalls).toEqual(['show']);
      expect(ujsHandler).not.toHaveBeenCalled();
      expect($.rails.handleMethod).not.toHaveBeenCalled();
    });

    // o force_posting.js registra um listener nativo no botão depois do ready do jQuery
    it('blocks listeners registered later on the same link', () => {
      const laterListener = jest.fn();
      document.getElementById('warned').addEventListener('click', laterListener);

      click('warned');

      expect(laterListener).not.toHaveBeenCalled();
    });

    it('posts the pending link through the ujs path when the user continues', () => {
      click('warned');
      $('#last-step-absence-warning-continue').trigger('click');

      expect($.rails.handleMethod).toHaveBeenCalledTimes(1);
      expect($.rails.handleMethod.mock.calls[0][0].attr('id')).toBe('warned');
      expect(modalCalls).toEqual(['show', 'hide']);
    });

    it('does not post twice when continue is clicked again', () => {
      click('warned');
      $('#last-step-absence-warning-continue').trigger('click');
      $('#last-step-absence-warning-continue').trigger('click');

      expect($.rails.handleMethod).toHaveBeenCalledTimes(1);
    });

    it('forgets the pending link when the modal is dismissed', () => {
      click('warned');
      $('#last-step-absence-warning-modal').trigger('hidden.bs.modal');
      $('#last-step-absence-warning-continue').trigger('click');

      expect($.rails.handleMethod).not.toHaveBeenCalled();
    });

    it('leaves links without the flag to the ujs handler', () => {
      const defaultAllowed = click('plain');

      expect(defaultAllowed).toBe(true);
      expect(modalCalls).toEqual([]);
      expect(ujsHandler).toHaveBeenCalledTimes(1);
    });
  });

  describe('when the page has no modal', () => {
    beforeEach(async () => {
      await setup(LINKS_HTML);
    });

    it('does not intercept any link', () => {
      const defaultAllowed = click('warned');

      expect(defaultAllowed).toBe(true);
      expect(modalCalls).toEqual([]);
      expect(ujsHandler).toHaveBeenCalledTimes(1);
    });
  });
});
