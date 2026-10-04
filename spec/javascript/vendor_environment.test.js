/**
 * @jest-environment jsdom
 */

// Garante que o ambiente comum de plugins vendorizados (spec/javascript/support/vendor_environment.js)
// cobre tudo que a aplicação carrega: a lista explícita é confrontada com o application.js.erb, então
// plugin novo no manifesto reprova aqui até alguém decidir se o Jest passa a carregá-lo.

const {
  BASE_LIBRARIES,
  VENDOR_PLUGINS,
  NOT_LOADED_VENDOR,
  loadVendor,
  loadVendorEnvironment,
  manifestVendorRequires
} = require('./support/vendor_environment');

function loadedVendor() {
  return BASE_LIBRARIES.concat(VENDOR_PLUGINS);
}

describe('manifest coverage', () => {
  it('loads only files the application manifest requires', () => {
    const manifest = manifestVendorRequires();

    loadedVendor().forEach((name) => {
      expect(manifest).toContain(name);
    });
  });

  it('classifies every vendored file the manifest requires', () => {
    const classified = loadedVendor().concat(Object.keys(NOT_LOADED_VENDOR));

    const unclassified = manifestVendorRequires().filter((name) => !classified.includes(name));

    expect(unclassified).toEqual([]);
  });

  it('does not list a file as both loaded and not loaded', () => {
    const both = VENDOR_PLUGINS.filter((name) => Object.keys(NOT_LOADED_VENDOR).includes(name));

    expect(both).toEqual([]);
  });
});

describe('loaded environment', () => {
  beforeAll(() => loadVendorEnvironment());

  it.each([['maxlength'], ['inputmask'], ['regexMask'], ['typeahead'], ['typeajax']])(
    'defines $.fn.%s',
    (name) => {
      expect(typeof window.jQuery.fn[name]).toBe('function');
    }
  );
});

describe('a page script calling a vendored plugin', () => {
  const CALLING_PLUGIN = "jQuery(function () { jQuery('#description').maxlength(); });";

  function setupPage(win) {
    win.document.body.innerHTML = '<input id="description">';
  }

  // janela própria por exemplo: o `ready` do jQuery é por documento e resolveria o callback
  // do exemplo anterior se a janela fosse compartilhada
  function pageWindow() {
    const iframe = document.createElement('iframe');

    document.body.appendChild(iframe);

    return iframe.contentWindow;
  }

  it('breaks when only the base libraries are loaded', async () => {
    const win = pageWindow();

    setupPage(win);
    loadVendor('jquery', win);
    loadVendor('underscore', win);
    await new Promise((resolve) => win.setTimeout(resolve, 0));

    expect(() => win.eval(CALLING_PLUGIN)).toThrow(/maxlength is not a function/);
  });

  it('runs when the vendor environment is loaded', async () => {
    const win = pageWindow();

    setupPage(win);
    await loadVendorEnvironment(win);

    expect(() => win.eval(CALLING_PLUGIN)).not.toThrow();
  });
});
