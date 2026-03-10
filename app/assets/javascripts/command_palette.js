(function() {
  'use strict';

  var items = [];
  var selectedIndex = 0;
  var isOpen = false;
  var lastQuery = null;
  var lastFiltered = [];

  var dom = {};

  function el(tag, attrs, children) {
    var node = document.createElement(tag);
    if (attrs) {
      Object.keys(attrs).forEach(function(key) {
        if (key === 'className') {
          node.className = attrs[key];
        } else if (key === 'textContent') {
          node.textContent = attrs[key];
        } else {
          node.setAttribute(key, attrs[key]);
        }
      });
    }
    if (children) {
      children.forEach(function(child) {
        if (typeof child === 'string') {
          node.appendChild(document.createTextNode(child));
        } else if (child) {
          node.appendChild(child);
        }
      });
    }
    return node;
  }

  function buildKbd(text) {
    return el('kbd', { textContent: text });
  }

  function createModal() {
    if (dom.overlay) return;

    var input = el('input', {
      id: 'command-palette-input',
      type: 'text',
      placeholder: 'Navegar para...',
      autocomplete: 'off'
    });

    var header = el('div', { id: 'command-palette-header' }, [input]);
    var list = el('div', { id: 'command-palette-list', role: 'listbox', 'aria-label': 'Resultados' });
    var empty = el('div', { id: 'command-palette-empty' }, ['Nenhum resultado encontrado']);

    var footer = el('div', { id: 'command-palette-footer' }, [
      el('span', null, [buildKbd('\u2191'), document.createTextNode(' '), buildKbd('\u2193'), document.createTextNode(' navegar')]),
      el('span', null, [buildKbd('Enter'), document.createTextNode(' abrir')]),
      el('span', null, [buildKbd('Esc'), document.createTextNode(' fechar')])
    ]);

    var modal = el('div', { id: 'command-palette' }, [header, list, empty, footer]);

    var overlay = el('div', {
      id: 'command-palette-overlay',
      role: 'dialog',
      'aria-modal': 'true',
      'aria-label': 'Navegar para'
    }, [modal]);

    overlay.addEventListener('click', function(e) {
      if (e.target === overlay) close();
    });

    document.body.appendChild(overlay);

    dom.overlay = overlay;
    dom.input = input;
    dom.list = list;
    dom.empty = empty;
  }

  function extractMenuItems() {
    var menuItems = [];
    var nav = document.querySelector('#left-panel nav > ul');
    if (!nav) return menuItems;

    var topLevelLis = nav.children;

    for (var i = 0; i < topLevelLis.length; i++) {
      var li = topLevelLis[i];
      var link = li.querySelector(':scope > a');
      if (!link) continue;

      var span = link.querySelector('.menu-item-parent');
      if (!span) continue;

      var label = span.textContent.trim();
      var iconEl = link.querySelector('i.fa');
      var iconClass = iconEl ? iconEl.className : '';
      var href = link.getAttribute('href');

      var submenu = li.querySelector(':scope > ul');

      if (submenu) {
        var subLis = submenu.children;
        for (var j = 0; j < subLis.length; j++) {
          var subLink = subLis[j].querySelector(':scope > a');
          if (!subLink) continue;

          var subHref = subLink.getAttribute('href');
          if (!subHref || subHref === 'javascript:void(0);' || subHref === '#') continue;

          var subLabel = subLink.textContent.trim();
          menuItems.push({
            label: subLabel,
            category: label,
            href: subHref,
            iconClass: ensureFixedWidth(iconClass),
            searchText: normalize(label + ' ' + subLabel)
          });
        }
      } else if (href && href !== 'javascript:void(0);' && href !== '#') {
        menuItems.push({
          label: label,
          category: '',
          href: href,
          iconClass: ensureFixedWidth(iconClass),
          searchText: normalize(label)
        });
      }
    }

    return menuItems;
  }

  function normalize(text) {
    return text
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '');
  }

  function fuzzyMatch(query, searchText) {
    if (!query) return true;
    var words = normalize(query).split(/\s+/).filter(Boolean);
    for (var i = 0; i < words.length; i++) {
      if (searchText.indexOf(words[i]) === -1) return false;
    }
    return true;
  }

  function ensureFixedWidth(iconClass) {
    if (!iconClass) return 'fa fa-fw fa-circle-o';
    if (iconClass.indexOf('fa-fw') === -1) {
      return iconClass + ' fa-fw';
    }
    return iconClass;
  }

  function buildItemElement(item, index, filtered) {
    var iconSpan = el('span', { className: 'cp-icon' }, [
      el('i', { className: item.iconClass })
    ]);

    var labelSpan = el('span', { className: 'cp-label', textContent: item.label });

    var children = [iconSpan, labelSpan];

    if (item.category) {
      children.push(el('span', { className: 'cp-category', textContent: item.category }));
    }

    var anchor = el('a', {
      className: 'cp-item' + (index === selectedIndex ? ' selected' : ''),
      href: item.href,
      role: 'option',
      'aria-selected': index === selectedIndex ? 'true' : 'false',
      'data-index': String(index)
    }, children);

    anchor.addEventListener('click', function(e) {
      e.preventDefault();
      var idx = parseInt(this.getAttribute('data-index'), 10);
      navigateTo(filtered[idx]);
    });

    return anchor;
  }

  function renderItems(filtered) {
    while (dom.list.firstChild) {
      dom.list.removeChild(dom.list.firstChild);
    }

    if (filtered.length === 0) {
      dom.empty.style.display = 'block';
      return;
    }

    dom.empty.style.display = 'none';

    for (var i = 0; i < filtered.length; i++) {
      dom.list.appendChild(buildItemElement(filtered[i], i, filtered));
    }
  }

  function updateSelection() {
    var listItems = dom.list.querySelectorAll('.cp-item');

    for (var i = 0; i < listItems.length; i++) {
      if (i === selectedIndex) {
        listItems[i].classList.add('selected');
        listItems[i].setAttribute('aria-selected', 'true');
        listItems[i].scrollIntoView({ block: 'nearest' });
      } else {
        listItems[i].classList.remove('selected');
        listItems[i].setAttribute('aria-selected', 'false');
      }
    }
  }

  function navigateTo(item) {
    if (item && item.href) {
      close();
      window.location.href = item.href;
    }
  }

  function getFilteredItems(query) {
    if (query === lastQuery) return lastFiltered;
    lastQuery = query;
    lastFiltered = items.filter(function(item) {
      return fuzzyMatch(query, item.searchText);
    });
    return lastFiltered;
  }

  function open() {
    if (isOpen) return;
    isOpen = true;

    createModal();

    items = extractMenuItems();
    selectedIndex = 0;
    lastQuery = null;
    lastFiltered = [];

    dom.input.value = '';
    renderItems(items);

    dom.overlay.classList.add('open');

    setTimeout(function() { dom.input.focus(); }, 50);

    dom.input.addEventListener('input', onInput);
    dom.input.addEventListener('keydown', onKeydown);
  }

  function close() {
    if (!isOpen) return;
    isOpen = false;

    if (dom.overlay) dom.overlay.classList.remove('open');

    if (dom.input) {
      dom.input.removeEventListener('input', onInput);
      dom.input.removeEventListener('keydown', onKeydown);
    }
  }

  function onInput() {
    var query = dom.input.value;
    var filtered = getFilteredItems(query);
    selectedIndex = 0;
    renderItems(filtered);
  }

  function onKeydown(e) {
    var filtered = getFilteredItems(dom.input.value);

    if (e.key === 'ArrowDown') {
      e.preventDefault();
      if (filtered.length > 0) {
        selectedIndex = (selectedIndex + 1) % filtered.length;
        updateSelection();
      }
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      if (filtered.length > 0) {
        selectedIndex = (selectedIndex - 1 + filtered.length) % filtered.length;
        updateSelection();
      }
    } else if (e.key === 'Enter') {
      e.preventDefault();
      if (filtered.length > 0 && filtered[selectedIndex]) {
        navigateTo(filtered[selectedIndex]);
      }
    } else if (e.key === 'Escape') {
      e.preventDefault();
      close();
    }
  }

  function isEditableElement(target) {
    if (!target) return false;
    var tag = target.tagName;
    if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') return true;
    if (target.isContentEditable) return true;
    return false;
  }

  function createTrigger() {
    var panel = document.getElementById('left-panel');
    if (!panel) return;

    var nav = panel.querySelector('nav');
    if (!nav) return;

    if (document.getElementById('cp-trigger')) return;

    var isMac = navigator.platform.toUpperCase().indexOf('MAC') >= 0;
    var shortcutLabel = isMac ? '\u2318K' : 'Ctrl+K';

    var trigger = el('div', { id: 'cp-trigger', title: 'Buscar no menu (' + shortcutLabel + ')' }, [
      el('i', { className: 'cp-trigger-icon fa fa-search' }),
      el('span', { className: 'cp-trigger-text', textContent: 'Buscar...' }),
      el('span', { className: 'cp-trigger-kbd', textContent: shortcutLabel })
    ]);

    trigger.addEventListener('click', function(e) {
      e.preventDefault();
      e.stopPropagation();
      open();
    });

    panel.insertBefore(trigger, nav);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', createTrigger);
  } else {
    createTrigger();
  }

  document.addEventListener('keydown', function(e) {
    var isCtrlK = (e.ctrlKey || e.metaKey) && e.key === 'k';
    if (!isCtrlK) return;

    if (isOpen) {
      e.preventDefault();
      close();
      return;
    }

    if (isEditableElement(document.activeElement)) return;

    e.preventDefault();
    open();
  });

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
      normalize: normalize,
      fuzzyMatch: fuzzyMatch,
      ensureFixedWidth: ensureFixedWidth,
      isEditableElement: isEditableElement,
      extractMenuItems: extractMenuItems
    };
  }
})();
