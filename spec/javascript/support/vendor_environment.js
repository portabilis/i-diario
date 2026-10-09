const fs = require('fs');
const path = require('path');

// Ambiente de plugins comum aos specs de caracterização: os scripts de produção rodam dentro de um
// callback de `ready` do jQuery, então um plugin ausente estoura ali e derruba todos os exemplos do
// arquivo antes de qualquer asserção.
// A lista carregada é explícita e conferida contra o application.js.erb pelo spec do helper: todo
// require do manifesto que não seja arquivo de app/assets/javascripts precisa estar na lista
// carregada ou em NOT_LOADED_ASSETS, e um plugin novo no manifesto reprova o spec até alguém
// decidir se o Jest passa a carregá-lo.
// O vendor/assets/javascripts/plugins.js que o manifesto inclui por bloco ERB fica fora do guard: é
// opcional, fora do controle de versão e muda de instalação para instalação.

const APP_PATH = path.resolve(__dirname, '../../../app/assets/javascripts');
const VENDOR_PATH = path.resolve(__dirname, '../../../vendor/assets/javascripts');
const MANIFEST_PATH = path.join(APP_PATH, 'application.js.erb');

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

// Assets que o manifesto carrega de fora da aplicação e que ficam fora do ambiente comum
const NOT_LOADED_ASSETS = {
  'jquery-ui': 'nenhum script caracterizado chama o jquery-ui direto; o datepicker-custom.js da aplicação depende dele para o datepicker, então um spec que o exercite precisa carregá-lo aqui',
  jquery_ujs: 'registra handlers delegados em document para todo link data-method; carrega só o spec que exercita o ujs, via loadVendor',
  smart_admin: 'manifesto do tema: roda também o app.js sobre o DOM, e nos specs select2, tooltip e modal são espiões',
  cocktail: 'mixins de Backbone, fora dos scripts caracterizados',
  backbone: 'nenhum script caracterizado usa o Backbone',
  'backbone.marionette': 'sobre o Backbone, fora dos scripts caracterizados',
  'backbone.server-errors-presenter': 'sobre o Backbone, fora dos scripts caracterizados',
  'backbone-validation': 'sobre o Backbone, fora dos scripts caracterizados',
  'backbone-validation-bootstrap': 'sobre o Backbone, fora dos scripts caracterizados',
  'backbone-nested-attributes/all': 'sobre o Backbone, fora dos scripts caracterizados',
  'ejs/ejs': 'templates client-side, fora dos scripts caracterizados',
  'handlebars.runtime': 'templates client-side, fora dos scripts caracterizados',
  'js-routes': 'rotas do Rails para o cliente, fora dos scripts caracterizados',
  cocoon: 'formulários aninhados, fora dos scripts caracterizados',
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
  'summernote-pt-BR': 'editor de texto, fora dos scripts caracterizados',
  bootbox: 'diálogos, fora dos scripts caracterizados',
  moment: 'datas, fora dos scripts caracterizados',
  'moment/pt-br': 'locale do moment, fora dos scripts caracterizados',
  'bootstrap-datetimepicker': 'seletor de data e hora, fora dos scripts caracterizados'
};

function appFile(name) {
  return path.join(APP_PATH, name + '.js');
}

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

// O ambiente comum não carrega o código da aplicação: cada spec carrega o seu pelo caminho. Por isso
// o guard parte do manifesto e olha só para os requires que não resolvem para app/assets/javascripts,
// sejam eles vendorizados ou servidos por gem.
// `//= require_tree` não casa: o separador do require é espaço, e no require_tree vem `_`.
// O Sprockets aceita espaço sobrando na diretiva, então a extração também aceita: um require que
// escapasse daqui carregaria na aplicação sem passar pelo guard
function requiredAssets(manifest) {
  const requires = manifest.match(/^\/\/=[ \t]*require[ \t]+\S+[ \t]*$/gm) || [];

  return requires.map((line) => line.replace(/^\/\/=[ \t]*require[ \t]+/, '').trim());
}

function manifestExternalRequires() {
  return requiredAssets(fs.readFileSync(MANIFEST_PATH, 'utf-8')).filter((name) => !fs.existsSync(appFile(name)));
}

module.exports = {
  BASE_LIBRARIES,
  VENDOR_PLUGINS,
  NOT_LOADED_ASSETS,
  loadIntoWindow,
  loadVendor,
  loadVendorEnvironment,
  manifestExternalRequires,
  requiredAssets
};
