/**
 * @jest-environment jsdom
 */

// Tests for command_palette.js
// Uses two approaches:
// 1. Direct imports for pure function unit tests (normalize, fuzzyMatch, etc.)
// 2. DOM interaction for integration tests (keyboard shortcuts, menu extraction, etc.)

const fs = require('fs');
const path = require('path');

const SCRIPT_PATH = path.resolve(__dirname, '../../app/assets/javascripts/command_palette.js');
const scriptContent = fs.readFileSync(SCRIPT_PATH, 'utf-8');

// Direct imports of pure functions via module.exports guard
const {
  normalize,
  fuzzyMatch,
  ensureFixedWidth,
  isEditableElement
} = require('../../app/assets/javascripts/command_palette');

// jsdom does not implement scrollIntoView - stub it globally for tests
Element.prototype.scrollIntoView = function() {};

function buildMenuDOM() {
  // Build the menu structure programmatically using safe DOM methods.
  // This mirrors the real i-Diário sidebar navigation structure.
  var panel = document.createElement('aside');
  panel.id = 'left-panel';

  var nav = document.createElement('nav');
  var ul = document.createElement('ul');

  // --- Cadastros (parent with submenu) ---
  var liCadastros = document.createElement('li');
  var aCadastros = document.createElement('a');
  aCadastros.href = 'javascript:void(0);';
  var iCadastros = document.createElement('i');
  iCadastros.className = 'fa fa-lg fa-fw fa-users';
  aCadastros.appendChild(iCadastros);
  var spanCadastros = document.createElement('span');
  spanCadastros.className = 'menu-item-parent';
  spanCadastros.textContent = 'Cadastros';
  aCadastros.appendChild(spanCadastros);
  liCadastros.appendChild(aCadastros);

  var ulCadastros = document.createElement('ul');
  var liAlunos = document.createElement('li');
  var aAlunos = document.createElement('a');
  aAlunos.href = '/students';
  aAlunos.textContent = 'Alunos';
  liAlunos.appendChild(aAlunos);
  ulCadastros.appendChild(liAlunos);

  var liProf = document.createElement('li');
  var aProf = document.createElement('a');
  aProf.href = '/teachers';
  aProf.textContent = 'Professores';
  liProf.appendChild(aProf);
  ulCadastros.appendChild(liProf);

  var liSep = document.createElement('li');
  var aSep = document.createElement('a');
  aSep.href = 'javascript:void(0);';
  aSep.textContent = 'Separador';
  liSep.appendChild(aSep);
  ulCadastros.appendChild(liSep);

  liCadastros.appendChild(ulCadastros);
  ul.appendChild(liCadastros);

  // --- Diário (parent with submenu) ---
  var liDiario = document.createElement('li');
  var aDiario = document.createElement('a');
  aDiario.href = 'javascript:void(0);';
  var iDiario = document.createElement('i');
  iDiario.className = 'fa fa-lg fa-fw fa-book';
  aDiario.appendChild(iDiario);
  var spanDiario = document.createElement('span');
  spanDiario.className = 'menu-item-parent';
  spanDiario.textContent = 'Di\u00e1rio';
  aDiario.appendChild(spanDiario);
  liDiario.appendChild(aDiario);

  var ulDiario = document.createElement('ul');
  var liFreq = document.createElement('li');
  var aFreq = document.createElement('a');
  aFreq.href = '/daily-frequencies';
  aFreq.textContent = 'Frequ\u00eancias';
  liFreq.appendChild(aFreq);
  ulDiario.appendChild(liFreq);

  var liConc = document.createElement('li');
  var aConc = document.createElement('a');
  aConc.href = '/conceptual-exams';
  aConc.textContent = 'Avalia\u00e7\u00f5es Conceituais';
  liConc.appendChild(aConc);
  ulDiario.appendChild(liConc);

  liDiario.appendChild(ulDiario);
  ul.appendChild(liDiario);

  // --- Painel (top-level link, no submenu) ---
  var liPainel = document.createElement('li');
  var aPainel = document.createElement('a');
  aPainel.href = '/dashboard';
  var iPainel = document.createElement('i');
  iPainel.className = 'fa fa-lg fa-fw fa-home';
  aPainel.appendChild(iPainel);
  var spanPainel = document.createElement('span');
  spanPainel.className = 'menu-item-parent';
  spanPainel.textContent = 'Painel';
  aPainel.appendChild(spanPainel);
  liPainel.appendChild(aPainel);
  ul.appendChild(liPainel);

  nav.appendChild(ul);
  panel.appendChild(nav);
  document.body.appendChild(panel);
}

// Executes the IIFE script within jsdom's window context so it has access
// to document, window, navigator, etc. Uses Function constructor because
// the script is our own trusted source file, loaded at test setup.
function loadCommandPalette() {
  // eslint-disable-next-line no-new-func
  var fn = new Function(scriptContent); // nosec: trusted own source file
  fn.call(window);
}

function pressCtrlK() {
  document.dispatchEvent(new KeyboardEvent('keydown', {
    key: 'k',
    ctrlKey: true,
    bubbles: true
  }));
}

function pressKey(target, key) {
  target.dispatchEvent(new KeyboardEvent('keydown', {
    key: key,
    bubbles: true
  }));
}

function typeInSearch(text) {
  var input = document.getElementById('command-palette-input');
  input.value = text;
  input.dispatchEvent(new Event('input', { bubbles: true }));
}

function getVisibleItems() {
  var list = document.getElementById('command-palette-list');
  return list ? list.querySelectorAll('.cp-item') : [];
}

function isOverlayOpen() {
  var overlay = document.getElementById('command-palette-overlay');
  return !!(overlay && overlay.classList.contains('open'));
}

// ============================================================
// Unit tests for pure functions (direct imports)
// ============================================================

describe('normalize', function() {
  it('converts to lowercase', function() {
    expect(normalize('Cadastros')).toBe('cadastros');
  });

  it('removes accents', function() {
    expect(normalize('Frequências')).toBe('frequencias');
  });

  it('handles combined diacritics', function() {
    expect(normalize('Avaliações Conceituais')).toBe('avaliacoes conceituais');
  });

  it('returns empty string for empty input', function() {
    expect(normalize('')).toBe('');
  });
});

describe('fuzzyMatch', function() {
  it('returns true for empty query', function() {
    expect(fuzzyMatch('', 'anything')).toBe(true);
  });

  it('matches single word', function() {
    expect(fuzzyMatch('aluno', 'cadastros alunos')).toBe(true);
  });

  it('matches multiple words', function() {
    expect(fuzzyMatch('diario frequencia', 'diario frequencias')).toBe(true);
  });

  it('returns false when word is missing', function() {
    expect(fuzzyMatch('xyz', 'cadastros alunos')).toBe(false);
  });

  it('is case insensitive (normalizes query internally)', function() {
    expect(fuzzyMatch('ALUNO', normalize('Alunos'))).toBe(true);
    expect(fuzzyMatch('aluno', normalize('Alunos'))).toBe(true);
  });
});

describe('ensureFixedWidth', function() {
  it('returns default class for empty input', function() {
    expect(ensureFixedWidth('')).toBe('fa fa-fw fa-circle-o');
  });

  it('returns default class for null input', function() {
    expect(ensureFixedWidth(null)).toBe('fa fa-fw fa-circle-o');
  });

  it('adds fa-fw when missing', function() {
    expect(ensureFixedWidth('fa fa-lg fa-users')).toBe('fa fa-lg fa-users fa-fw');
  });

  it('does not duplicate fa-fw', function() {
    expect(ensureFixedWidth('fa fa-fw fa-users')).toBe('fa fa-fw fa-users');
  });
});

describe('isEditableElement', function() {
  it('returns false for null', function() {
    expect(isEditableElement(null)).toBe(false);
  });

  it('returns true for input', function() {
    var input = document.createElement('input');
    expect(isEditableElement(input)).toBe(true);
  });

  it('returns true for textarea', function() {
    var textarea = document.createElement('textarea');
    expect(isEditableElement(textarea)).toBe(true);
  });

  it('returns true for select', function() {
    var select = document.createElement('select');
    expect(isEditableElement(select)).toBe(true);
  });

  it('returns true for contentEditable element', function() {
    var div = document.createElement('div');
    Object.defineProperty(div, 'isContentEditable', { value: true });
    expect(isEditableElement(div)).toBe(true);
  });

  it('returns false for regular div', function() {
    var div = document.createElement('div');
    expect(isEditableElement(div)).toBe(false);
  });
});

// ============================================================
// Integration tests via DOM interaction
// ============================================================

describe('Command Palette', function() {
  beforeEach(function() {
    buildMenuDOM();
    loadCommandPalette();
  });

  afterEach(function() {
    // Clean up DOM completely between tests
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  describe('trigger element', function() {
    it('creates a search trigger in the sidebar', function() {
      var trigger = document.getElementById('cp-trigger');
      expect(trigger).not.toBeNull();
    });

    it('displays search icon and label', function() {
      var trigger = document.getElementById('cp-trigger');
      var icon = trigger.querySelector('.cp-trigger-icon');
      var text = trigger.querySelector('.cp-trigger-text');

      expect(icon).not.toBeNull();
      expect(icon.classList.contains('fa-search')).toBe(true);
      expect(text.textContent).toBe('Buscar...');
    });

    it('displays keyboard shortcut badge', function() {
      var kbd = document.querySelector('#cp-trigger .cp-trigger-kbd');
      expect(kbd).not.toBeNull();
      // Should be either Ctrl+K or ⌘K depending on platform
      expect(kbd.textContent).toMatch(/Ctrl\+K|\u2318K/);
    });

    it('opens command palette on click', function() {
      var trigger = document.getElementById('cp-trigger');
      trigger.click();

      expect(isOverlayOpen()).toBe(true);
    });

    it('does not create duplicate triggers', function() {
      // Script already ran in beforeEach, loading again should not duplicate
      loadCommandPalette();

      var triggers = document.querySelectorAll('#cp-trigger');
      expect(triggers.length).toBe(1);
    });
  });

  describe('keyboard shortcut', function() {
    // Save and restore document.activeElement descriptor since some tests override it
    var originalActiveElementDescriptor;

    beforeEach(function() {
      originalActiveElementDescriptor = Object.getOwnPropertyDescriptor(Document.prototype, 'activeElement')
        || Object.getOwnPropertyDescriptor(document, 'activeElement');
    });

    afterEach(function() {
      // Restore activeElement to its original behavior
      if (originalActiveElementDescriptor) {
        Object.defineProperty(document, 'activeElement', originalActiveElementDescriptor);
      } else {
        delete document.activeElement;
      }
    });

    it('opens palette with Ctrl+K', function() {
      pressCtrlK();
      expect(isOverlayOpen()).toBe(true);
    });

    it('closes palette with Ctrl+K when already open', function() {
      pressCtrlK();
      expect(isOverlayOpen()).toBe(true);

      pressCtrlK();
      expect(isOverlayOpen()).toBe(false);
    });

    it('does not open when focus is on an input element', function() {
      var input = document.createElement('input');
      document.body.appendChild(input);
      input.focus();

      Object.defineProperty(document, 'activeElement', {
        get: function() { return input; },
        configurable: true
      });

      pressCtrlK();
      expect(isOverlayOpen()).toBe(false);
    });

    it('does not open when focus is on a textarea', function() {
      var textarea = document.createElement('textarea');
      document.body.appendChild(textarea);
      textarea.focus();

      Object.defineProperty(document, 'activeElement', {
        get: function() { return textarea; },
        configurable: true
      });

      pressCtrlK();
      expect(isOverlayOpen()).toBe(false);
    });

    it('does not open when focus is on a contentEditable element', function() {
      var div = document.createElement('div');
      document.body.appendChild(div);

      // jsdom does not implement isContentEditable, so we define it manually
      Object.defineProperty(div, 'isContentEditable', { value: true });

      Object.defineProperty(document, 'activeElement', {
        get: function() { return div; },
        configurable: true
      });

      pressCtrlK();
      expect(isOverlayOpen()).toBe(false);
    });
  });

  describe('modal structure', function() {
    beforeEach(function() {
      pressCtrlK();
    });

    it('creates the overlay with dialog role', function() {
      var overlay = document.getElementById('command-palette-overlay');
      expect(overlay).not.toBeNull();
      expect(overlay.getAttribute('role')).toBe('dialog');
      expect(overlay.getAttribute('aria-modal')).toBe('true');
    });

    it('creates the search input', function() {
      var input = document.getElementById('command-palette-input');
      expect(input).not.toBeNull();
      expect(input.getAttribute('placeholder')).toBe('Navegar para...');
      expect(input.getAttribute('autocomplete')).toBe('off');
    });

    it('creates the results list with listbox role', function() {
      var list = document.getElementById('command-palette-list');
      expect(list).not.toBeNull();
      expect(list.getAttribute('role')).toBe('listbox');
    });

    it('creates the footer with keyboard hints', function() {
      var footer = document.getElementById('command-palette-footer');
      expect(footer).not.toBeNull();

      var kbds = footer.querySelectorAll('kbd');
      expect(kbds.length).toBeGreaterThanOrEqual(3);
    });

    it('closes when clicking the overlay background', function() {
      var overlay = document.getElementById('command-palette-overlay');
      overlay.dispatchEvent(new MouseEvent('click', { bubbles: true }));

      expect(isOverlayOpen()).toBe(false);
    });

    it('does not close when clicking inside the modal', function() {
      var modal = document.getElementById('command-palette');
      modal.dispatchEvent(new MouseEvent('click', { bubbles: true }));

      expect(isOverlayOpen()).toBe(true);
    });
  });

  describe('menu extraction', function() {
    beforeEach(function() {
      pressCtrlK();
    });

    it('extracts submenu items with parent category', function() {
      var items = getVisibleItems();
      var labels = Array.from(items).map(function(el) {
        return el.querySelector('.cp-label').textContent;
      });

      expect(labels).toContain('Alunos');
      expect(labels).toContain('Professores');
      expect(labels).toContain('Frequ\u00eancias');
      expect(labels).toContain('Avalia\u00e7\u00f5es Conceituais');
    });

    it('extracts top-level items without submenu', function() {
      var items = getVisibleItems();
      var labels = Array.from(items).map(function(el) {
        return el.querySelector('.cp-label').textContent;
      });

      expect(labels).toContain('Painel');
    });

    it('shows parent category for submenu items', function() {
      var items = getVisibleItems();
      var alunosItem = Array.from(items).find(function(el) {
        return el.querySelector('.cp-label').textContent === 'Alunos';
      });

      var category = alunosItem.querySelector('.cp-category');
      expect(category.textContent).toBe('Cadastros');
    });

    it('does not show category for top-level items', function() {
      var items = getVisibleItems();
      var painelItem = Array.from(items).find(function(el) {
        return el.querySelector('.cp-label').textContent === 'Painel';
      });

      var category = painelItem.querySelector('.cp-category');
      expect(category).toBeNull();
    });

    it('skips links with javascript:void(0) href', function() {
      var items = getVisibleItems();
      var labels = Array.from(items).map(function(el) {
        return el.querySelector('.cp-label').textContent;
      });

      expect(labels).not.toContain('Separador');
    });

    it('preserves icon classes from menu with fa-fw', function() {
      var items = getVisibleItems();
      var alunosItem = Array.from(items).find(function(el) {
        return el.querySelector('.cp-label').textContent === 'Alunos';
      });

      var icon = alunosItem.querySelector('.cp-icon i');
      expect(icon.className).toContain('fa-users');
      expect(icon.className).toContain('fa-fw');
    });

    it('sets correct href on items', function() {
      var items = getVisibleItems();
      var alunosItem = Array.from(items).find(function(el) {
        return el.querySelector('.cp-label').textContent === 'Alunos';
      });

      expect(alunosItem.getAttribute('href')).toBe('/students');
    });
  });

  describe('search and filtering', function() {
    beforeEach(function() {
      pressCtrlK();
    });

    it('filters items by search text', function() {
      typeInSearch('aluno');

      var items = getVisibleItems();
      expect(items.length).toBe(1);
      expect(items[0].querySelector('.cp-label').textContent).toBe('Alunos');
    });

    it('searches in category name too', function() {
      typeInSearch('cadastro');

      var items = getVisibleItems();
      var labels = Array.from(items).map(function(el) {
        return el.querySelector('.cp-label').textContent;
      });

      expect(labels).toContain('Alunos');
      expect(labels).toContain('Professores');
    });

    it('supports multi-word search', function() {
      typeInSearch('diario frequencia');

      var items = getVisibleItems();
      expect(items.length).toBe(1);
      expect(items[0].querySelector('.cp-label').textContent).toBe('Frequ\u00eancias');
    });

    it('normalizes accents in search', function() {
      typeInSearch('avaliacoes');

      var items = getVisibleItems();
      expect(items.length).toBe(1);
      expect(items[0].querySelector('.cp-label').textContent).toBe('Avalia\u00e7\u00f5es Conceituais');
    });

    it('is case insensitive', function() {
      typeInSearch('ALUNOS');

      var items = getVisibleItems();
      expect(items.length).toBe(1);
      expect(items[0].querySelector('.cp-label').textContent).toBe('Alunos');
    });

    it('shows all items when search is empty', function() {
      typeInSearch('aluno');
      expect(getVisibleItems().length).toBe(1);

      typeInSearch('');
      expect(getVisibleItems().length).toBe(5);
    });

    it('shows empty state when no results', function() {
      typeInSearch('xyznonexistent');

      var items = getVisibleItems();
      expect(items.length).toBe(0);

      var empty = document.getElementById('command-palette-empty');
      expect(empty.style.display).toBe('block');
    });

    it('hides empty state when there are results', function() {
      typeInSearch('aluno');

      var empty = document.getElementById('command-palette-empty');
      expect(empty.style.display).toBe('none');
    });
  });

  describe('keyboard navigation', function() {
    beforeEach(function() {
      pressCtrlK();
    });

    it('first item is selected by default', function() {
      var items = getVisibleItems();
      expect(items[0].classList.contains('selected')).toBe(true);
      expect(items[0].getAttribute('aria-selected')).toBe('true');
    });

    it('moves selection down with ArrowDown', function() {
      var input = document.getElementById('command-palette-input');
      pressKey(input, 'ArrowDown');

      var items = getVisibleItems();
      expect(items[0].classList.contains('selected')).toBe(false);
      expect(items[1].classList.contains('selected')).toBe(true);
    });

    it('moves selection up with ArrowUp', function() {
      var input = document.getElementById('command-palette-input');
      pressKey(input, 'ArrowDown');
      pressKey(input, 'ArrowUp');

      var items = getVisibleItems();
      expect(items[0].classList.contains('selected')).toBe(true);
    });

    it('wraps selection from last to first with ArrowDown', function() {
      var input = document.getElementById('command-palette-input');
      var totalItems = getVisibleItems().length;

      for (var i = 0; i < totalItems; i++) {
        pressKey(input, 'ArrowDown');
      }

      var items = getVisibleItems();
      expect(items[0].classList.contains('selected')).toBe(true);
    });

    it('wraps selection from first to last with ArrowUp', function() {
      var input = document.getElementById('command-palette-input');
      pressKey(input, 'ArrowUp');

      var items = getVisibleItems();
      var lastItem = items[items.length - 1];
      expect(lastItem.classList.contains('selected')).toBe(true);
    });

    it('closes palette with Escape', function() {
      var input = document.getElementById('command-palette-input');
      pressKey(input, 'Escape');

      expect(isOverlayOpen()).toBe(false);
    });

    it('resets selection when search changes', function() {
      var input = document.getElementById('command-palette-input');
      pressKey(input, 'ArrowDown');
      pressKey(input, 'ArrowDown');

      typeInSearch('a');

      var items = getVisibleItems();
      if (items.length > 0) {
        expect(items[0].classList.contains('selected')).toBe(true);
      }
    });
  });

  describe('navigation', function() {
    // jsdom does not support window.location.href navigation, so we
    // test that: (1) the palette closes after selecting an item,
    // (2) the correct href is set on each rendered item, and
    // (3) Enter/click target the correctly selected item.

    beforeEach(function() {
      pressCtrlK();
    });

    it('closes the palette on Enter', function() {
      var input = document.getElementById('command-palette-input');
      pressKey(input, 'Enter');

      expect(isOverlayOpen()).toBe(false);
    });

    it('first item has correct href', function() {
      var items = getVisibleItems();
      expect(items[0].getAttribute('href')).toBe('/students');
    });

    it('ArrowDown changes which item would be navigated', function() {
      var input = document.getElementById('command-palette-input');
      pressKey(input, 'ArrowDown');

      var items = getVisibleItems();
      var selected = Array.from(items).find(function(el) {
        return el.classList.contains('selected');
      });
      expect(selected.getAttribute('href')).toBe('/teachers');
    });

    it('closes the palette on item click', function() {
      var items = getVisibleItems();
      items[0].click();

      expect(isOverlayOpen()).toBe(false);
    });
  });

  describe('open and close lifecycle', function() {
    it('does not reopen if already open', function() {
      pressCtrlK();
      expect(isOverlayOpen()).toBe(true);

      // Clicking trigger while open should not cause issues
      var trigger = document.getElementById('cp-trigger');
      trigger.click();

      expect(isOverlayOpen()).toBe(true);
    });

    it('clears search input on reopen', function() {
      pressCtrlK();
      typeInSearch('test');

      pressKey(document.getElementById('command-palette-input'), 'Escape');
      expect(isOverlayOpen()).toBe(false);

      pressCtrlK();
      var input = document.getElementById('command-palette-input');
      expect(input.value).toBe('');
    });

    it('shows all items on reopen', function() {
      pressCtrlK();
      typeInSearch('aluno');
      expect(getVisibleItems().length).toBe(1);

      pressKey(document.getElementById('command-palette-input'), 'Escape');

      pressCtrlK();
      expect(getVisibleItems().length).toBe(5);
    });
  });

  describe('edge cases', function() {
    it('handles missing left-panel gracefully', function() {
      while (document.body.firstChild) {
        document.body.removeChild(document.body.firstChild);
      }
      expect(function() {
        loadCommandPalette();
      }).not.toThrow();
    });

    it('handles empty navigation', function() {
      while (document.body.firstChild) {
        document.body.removeChild(document.body.firstChild);
      }
      var panel = document.createElement('aside');
      panel.id = 'left-panel';
      var nav = document.createElement('nav');
      var ul = document.createElement('ul');
      nav.appendChild(ul);
      panel.appendChild(nav);
      document.body.appendChild(panel);

      loadCommandPalette();
      pressCtrlK();
      expect(getVisibleItems().length).toBe(0);
    });

    it('handles navigation without ul', function() {
      while (document.body.firstChild) {
        document.body.removeChild(document.body.firstChild);
      }
      var panel = document.createElement('aside');
      panel.id = 'left-panel';
      var nav = document.createElement('nav');
      panel.appendChild(nav);
      document.body.appendChild(panel);

      loadCommandPalette();
      pressCtrlK();
      expect(getVisibleItems().length).toBe(0);
    });
  });
});
