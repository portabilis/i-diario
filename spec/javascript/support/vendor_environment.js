const fs = require('fs');
const path = require('path');

// Ambiente vendorizado comum aos specs de caracterização: os scripts de produção rodam
// dentro de um callback de `ready` do jQuery, então um plugin ausente estoura ali e derruba
// todos os exemplos do arquivo antes de qualquer asserção.
// A lista carregada é explícita e conferida contra o application.js.erb pelo spec do helper:
// plugin novo no manifesto reprova até alguém decidir se o Jest passa a carregá-lo.

const VENDOR_PATH = path.resolve(__dirname, '../../../vendor/assets/javascripts');
const MANIFEST_PATH = path.resolve(__dirname, '../../../app/assets/javascripts/application.js.erb');

const BASE_LIBRARIES = ['jquery', 'underscore'];

// Plugins do manifesto que os scripts caracterizados chamam; a ordem segue a do manifesto
const VENDOR_PLUGINS = [
  'inputmask/inputmask',
  'inputmask/inputmask.numeric.extensions',
  'inputmask/jquery.inputmask',
  'bootstrap-typeahead',
  'typeajax',
  'jquery-maxlength.min',
  'jquery-regex-mask'
];

// Vendorizados pelo manifesto que ficam fora do ambiente comum
const NOT_LOADED_VENDOR = {
  'jquery-ui': 'o datepicker e o tooltip do tema vêm do smart_admin; nenhum script caracterizado chama o jquery-ui direto',
  jquery_ujs: 'registra handlers delegados em document para todo link data-method; carrega só o spec que exercita o ujs, via loadVendor',
  smart_admin: 'manifesto do tema: roda também o app.js sobre o DOM, e nos specs select2, tooltip e modal são espiões',
  cocktail: 'mixins de Backbone, fora dos scripts caracterizados',
  backbone: 'a aplicação ainda não é usada por nenhum script caracterizado',
  'backbone.marionette': 'sobre o Backbone, fora dos scripts caracterizados',
  'backbone.server-errors-presenter': 'sobre o Backbone, fora dos scripts caracterizados',
  'backbone-validation': 'sobre o Backbone, fora dos scripts caracterizados',
  'backbone-validation-bootstrap': 'sobre o Backbone, fora dos scripts caracterizados',
  'ejs/ejs': 'templates client-side, fora dos scripts caracterizados',
  'jquery-file-upload/vendor/jquery.ui.widget': 'upload de arquivos, fora dos scripts caracterizados',
  'jquery-file-upload/vendor/load-image.all.min': 'upload de arquivos, fora dos scripts caracterizados',
  'jquery-file-upload/vendor/canvas-to-blob.min': 'upload de arquivos, fora dos scripts caracterizados',
  'jquery-file-upload/jquery.iframe-transport': 'upload de arquivos, fora dos scripts caracterizados',
  'jquery-file-upload/jquery.fileupload': 'upload de arquivos, fora dos scripts caracterizados',
  'jquery-file-upload/jquery.fileupload-process': 'upload de arquivos, fora dos scripts caracterizados',
  'jquery-file-upload/jquery.fileupload-image': 'upload de arquivos, fora dos scripts caracterizados',
  'jquery-file-upload/jquery.fileupload-validate': 'upload de arquivos, fora dos scripts caracterizados',
  'chart/chart.min': 'gráficos, fora dos scripts caracterizados',
  'raphael.min': 'gráficos, fora dos scripts caracterizados',
  morris: 'gráficos, fora dos scripts caracterizados',
  'summernote.min': 'editor de texto, fora dos scripts caracterizados',
  'summernote-pt-BR': 'editor de texto, fora dos scripts caracterizados'
};

function vendorFile(name) {
  return path.join(VENDOR_PATH, name + '.js');
}

function loadIntoWindow(file, win = window) {
  win.eval(fs.readFileSync(file, 'utf-8'));
}

function loadVendor(name, win = window) {
  loadIntoWindow(vendorFile(name), win);
}

async function loadVendorEnvironment(win = window) {
  BASE_LIBRARIES.concat(VENDOR_PLUGINS).forEach((name) => loadVendor(name, win));

  // deixa o `ready` do jQuery resolver; a partir daqui os callbacks rodam na hora
  await new Promise((resolve) => win.setTimeout(resolve, 0));
}

// `//= require_tree` não casa: o separador do require é espaço, e no require_tree vem `_`
function manifestVendorRequires() {
  const requires = fs.readFileSync(MANIFEST_PATH, 'utf-8').match(/^\/\/= require (\S+)$/gm) || [];

  return requires
    .map((line) => line.replace('//= require ', ''))
    .filter((name) => fs.existsSync(vendorFile(name)));
}

module.exports = {
  VENDOR_PATH,
  BASE_LIBRARIES,
  VENDOR_PLUGINS,
  NOT_LOADED_VENDOR,
  vendorFile,
  loadIntoWindow,
  loadVendor,
  loadVendorEnvironment,
  manifestVendorRequires
};
