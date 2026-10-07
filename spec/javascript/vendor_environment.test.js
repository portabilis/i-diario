/**
 * @jest-environment jsdom
 */

// Garante que o ambiente comum de plugins (spec/javascript/support/vendor_environment.js) acompanha o que
// o application.js.erb carrega: todo require do manifesto que não seja arquivo de app/assets/javascripts
// precisa estar na lista carregada ou em NOT_LOADED_ASSETS, então plugin novo reprova aqui até alguém
// decidir se o Jest passa a carregá-lo.

const {
  BASE_LIBRARIES,
  VENDOR_PLUGINS,
  NOT_LOADED_ASSETS,
  loadVendor,
  loadVendorEnvironment,
  manifestExternalRequires,
  requiredAssets
} = require('./support/vendor_environment');

function loadedVendor() {
  return BASE_LIBRARIES.concat(VENDOR_PLUGINS);
}

describe('manifest coverage', () => {
  it('loads only files the application manifest requires', () => {
    const manifest = manifestExternalRequires();

    loadedVendor().forEach((name) => {
      expect(manifest).toContain(name);
    });
  });

  it('classifies every asset the manifest loads from outside the application', () => {
    const classified = loadedVendor().concat(Object.keys(NOT_LOADED_ASSETS));

    const unclassified = manifestExternalRequires().filter((name) => !classified.includes(name));

    expect(unclassified).toEqual([]);
  });

  // O bootbox vem de gem: não existe em vendor/assets/javascripts, então só entra na lista (e na
  // classificação) se o guard olhar além dos arquivos vendorizados.
  it('covers the assets the manifest takes from gems, not only the vendored ones', () => {
    expect(manifestExternalRequires()).toContain('bootbox');
  });

  it('reads require directives with extra whitespace and skips require_tree', () => {
    const manifest = [
      '//= require bootbox ',
      '//=  require\tmoment',
      '//= require_tree .',
      '//= require jquery'
    ].join('\n');

    expect(requiredAssets(manifest)).toEqual(['bootbox', 'moment', 'jquery']);
  });

  it('does not list a file as both loaded and not loaded', () => {
    const both = VENDOR_PLUGINS.filter((name) => Object.keys(NOT_LOADED_ASSETS).includes(name));

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
