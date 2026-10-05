/**
 * @jest-environment jsdom
 */

// Testes de app/assets/javascripts/views/ieducar_api_exam_posting/last_step_absence_warning.js.
//
// Os links de envio são `link_to ... method: :post`: o jquery_ujs os trata num handler delegado
// em `document`. O script intercepta só os links marcados com data-last-step-absence-warning,
// abre a modal e, na confirmação, dispara o POST pelo mesmo caminho do ujs ($.rails.handleMethod).
//
// O jquery_ujs entra aqui de verdade, não como stub: `disableElement` (o data-disable-with) mora
// no handler de clique dele, que a interceptação pula — só com o ujs real dá para afirmar que o
// botão vira "Enviando..." e que um segundo envio não passa.

const fs = require('fs');
const path = require('path');

const { loadVendor, loadVendorEnvironment } = require('./support/vendor_environment');
const PAGE_PATH = path.resolve(
  __dirname,
  '../../app/assets/javascripts/views/ieducar_api_exam_posting/last_step_absence_warning.js'
);

const pageSource = fs.readFileSync(PAGE_PATH, 'utf-8');

const MODAL_HTML =
  '<div class="modal fade" id="last-step-absence-warning-modal">' +
  '  <button type="button" id="last-step-absence-warning-continue">Continuar envio</button>' +
  '</div>';

// Espelha o _resources.html.erb na linha de faltas da última etapa: o "Repetir envio" marcado
// troca o onclick inline pelos data-resend-*, e o "Enviar" carrega o data-disable-with.
// href="#" evita o jsdom tentar navegar quando o clique não é interceptado
const LINKS_HTML =
  '<a id="btn-posting-0-3" href="#" data-method="post" data-last-step-absence-warning="true"' +
  '   data-resend-index="0" data-resend-step-id="3">Repetir envio</a>' +
  '<a id="warned" href="#" data-method="post" data-last-step-absence-warning="true"' +
  '   data-disable-with="Enviando...">Enviar</a>' +
  '<a id="plain" href="#" data-method="post" data-disable-with="Enviando...">Enviar</a>';

let modalCalls;
let posts;
let $;

function stubModalPlugin() {
  modalCalls = [];

  $.fn.modal = function (action) {
    modalCalls.push(action);

    return this;
  };
}

// O jsdom não implementa submit(): registra o destino em vez de navegar.
function stubFormSubmit() {
  posts = [];

  window.HTMLFormElement.prototype.submit = function () {
    posts.push($(this).attr('action'));
  };
}

async function setup(html) {
  document.body.innerHTML = html;
  stubModalPlugin();
  stubFormSubmit();
  jest.spyOn($.rails, 'handleMethod');
  window.resend_posting = jest.fn();
  window.eval(pageSource);

  // o script registra os handlers no ready do jQuery
  await new Promise((resolve) => setTimeout(resolve, 0));
}

function click(id) {
  const element = document.getElementById(id);

  return element.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
}

function continueSending() {
  $('#last-step-absence-warning-continue').trigger('click');
}

beforeAll(async () => {
  await loadVendorEnvironment();
  $ = window.jQuery;
  loadVendor('jquery_ujs');
});

afterEach(() => {
  jest.restoreAllMocks();
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
      expect(posts).toEqual([]);
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
      continueSending();

      expect($.rails.handleMethod).toHaveBeenCalledTimes(1);
      expect($.rails.handleMethod.mock.calls[0][0].attr('id')).toBe('warned');
      expect(posts).toEqual(['#']);
      expect(modalCalls).toEqual(['show', 'hide']);
    });

    it('applies the disable_with of the link when the user continues', () => {
      click('warned');
      continueSending();

      expect(document.getElementById('warned').innerHTML).toEqual('Enviando...');
    });

    it('does not post again when the flagged link is clicked after continuing', () => {
      click('warned');
      continueSending();

      click('warned');
      continueSending();

      expect(posts).toEqual(['#']);
      expect(modalCalls.filter((call) => call === 'show')).toEqual(['show']);
    });

    it('does not post twice when continue is clicked again', () => {
      click('warned');
      continueSending();
      continueSending();

      expect($.rails.handleMethod).toHaveBeenCalledTimes(1);
    });

    it('forgets the pending link when the modal is dismissed', () => {
      click('warned');
      $('#last-step-absence-warning-modal').trigger('hidden.bs.modal');
      continueSending();

      expect($.rails.handleMethod).not.toHaveBeenCalled();
      expect(posts).toEqual([]);
    });

    it('leaves links without the flag to the ujs handler', () => {
      const defaultAllowed = click('plain');

      expect(defaultAllowed).toBe(false);
      expect(modalCalls).toEqual([]);
      expect(posts).toEqual(['#']);
      expect(document.getElementById('plain').innerHTML).toEqual('Enviando...');
    });

    // O marcador de cooldown de 30 min do force_posting.js não pode valer para um envio que o
    // usuário recusou: sem isso o botão fica inerte no carregamento seguinte sem nada ter sido
    // enviado.
    it('does not track the resend click when the user cancels', () => {
      click('btn-posting-0-3');
      $('#last-step-absence-warning-modal').trigger('hidden.bs.modal');

      expect(window.resend_posting).not.toHaveBeenCalled();
      expect(posts).toEqual([]);
    });

    it('tracks the resend click when the user continues', () => {
      click('btn-posting-0-3');
      continueSending();

      expect(window.resend_posting).toHaveBeenCalledTimes(1);
      expect(window.resend_posting).toHaveBeenCalledWith(0, 3);
      expect(posts).toEqual(['#']);
    });
  });

  describe('when the page has no modal', () => {
    beforeEach(async () => {
      await setup(LINKS_HTML);
    });

    it('does not intercept any link', () => {
      const defaultAllowed = click('warned');

      expect(defaultAllowed).toBe(false);
      expect(modalCalls).toEqual([]);
      expect(posts).toEqual(['#']);
      expect(document.getElementById('warned').innerHTML).toEqual('Enviando...');
    });
  });
});
