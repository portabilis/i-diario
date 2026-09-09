/**
 * @jest-environment jsdom
 */

// Testes de app/assets/javascripts/views/ieducar_api_exam_posting/force_posting.js.
//
// O "Repetir envio" fica bloqueado por 30 minutos depois de usado. O tempo já cumprido vive em
// `paid` no localStorage e é gravado a cada segundo, então o bloqueio atravessa recarregamentos:
// quem já esperou 10 minutos volta faltando 20, não 30.

const fs = require('fs');
const path = require('path');

const PAGE_PATH = path.resolve(
  __dirname,
  '../../app/assets/javascripts/views/ieducar_api_exam_posting/force_posting.js'
);

const pageSource = fs.readFileSync(PAGE_PATH, 'utf-8');

const BUTTON_ID = 'btn-posting-0-3';
const PAGE_HTML =
  '<a id="' + BUTTON_ID + '" href="#">Repetir envio</a>' +
  '<a id="send-button" href="#">Enviar</a>';

const ONE_MINUTE = 60000;
const COOLDOWN = 30 * ONE_MINUTE;

// Cada carregamento da tela roda o arquivo de novo: é o startData que relê o localStorage e
// decide se o botão entra bloqueado.
function loadPage() {
  document.body.innerHTML = PAGE_HTML;
  window.eval(pageSource);
}

// Sair da tela mata os timers da página anterior; ao voltar só o localStorage sobrevive.
function leaveAndComeBack() {
  jest.useRealTimers();
  jest.useFakeTimers();
  loadPage();
}

function blocked() {
  return document.getElementById(BUTTON_ID).style.pointerEvents === 'none';
}

function servedTime() {
  return JSON.parse(localStorage.getItem('click-tracking'))[BUTTON_ID].paid;
}

beforeEach(() => {
  localStorage.clear();
  jest.useFakeTimers();
});

afterEach(() => {
  jest.useRealTimers();
});

describe('resend posting cooldown', () => {
  beforeEach(() => {
    loadPage();
    window.resend_posting(0, 3);
    loadPage();
  });

  it('blocks the button right after the click', () => {
    expect(blocked()).toBe(true);
    expect(servedTime()).toEqual(0);
  });

  it('records the time served while the page stays open', () => {
    jest.advanceTimersByTime(10 * ONE_MINUTE);

    expect(servedTime()).toEqual(10 * ONE_MINUTE);
    expect(blocked()).toBe(true);
  });

  it('keeps the time served when the user leaves and comes back', () => {
    jest.advanceTimersByTime(10 * ONE_MINUTE);

    leaveAndComeBack();

    expect(servedTime()).toEqual(10 * ONE_MINUTE);
    expect(blocked()).toBe(true);
  });

  it('releases the button after the remaining time, not a whole new cooldown', () => {
    jest.advanceTimersByTime(10 * ONE_MINUTE);

    leaveAndComeBack();
    jest.advanceTimersByTime(COOLDOWN - 10 * ONE_MINUTE);

    expect(blocked()).toBe(false);
  });

  it('does not block again on the next page load once the cooldown is over', () => {
    jest.advanceTimersByTime(COOLDOWN);

    loadPage();

    expect(blocked()).toBe(false);
  });
});
