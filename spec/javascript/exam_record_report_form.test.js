/**
 * @jest-environment jsdom
 */

// Testes de app/assets/javascripts/views/exam_record_report/form.js: a troca de escola e a troca
// de turma recarregam as listas pelas actions do próprio relatório, e a disciplina só é
// pré-selecionada quando é a única da turma.

const fs = require('fs');
const path = require('path');

const VENDOR_PATH = path.resolve(__dirname, '../../vendor/assets/javascripts');
const SCRIPT_PATH = path.resolve(
  __dirname,
  '../../app/assets/javascripts/views/exam_record_report/form.js'
);

const scriptSource = fs.readFileSync(SCRIPT_PATH, 'utf-8');

let requests;

function loadIntoWindow(file) {
  window.eval(fs.readFileSync(file, 'utf-8'));
}

function formHtml() {
  return `
    <form>
      <input id="exam_record_report_form_unity_id" type="hidden" value="1">
      <input id="exam_record_report_form_classroom_id" type="hidden" value="10">
      <input id="exam_record_report_form_discipline_id" type="hidden" value="100">
      <input id="exam_record_report_form_school_calendar_step_id" type="hidden" value="">
      <button id="send-form"></button>
    </form>
  `;
}

// O select2 real não roda no jsdom; o stub guarda as opções carregadas para o teste conferir.
function stubPlugins() {
  const $ = window.jQuery;

  $.fn.select2 = function (option) {
    if (option === 'val') return this.val();
    if (option && option.data) this.data('options', option.data);

    return this;
  };
}

function stubGlobals() {
  window.FlashMessages = function () {
    this.info = jest.fn();
    this.error = jest.fn();
  };

  const path = (name) => (params) => `/${name}?${window.jQuery.param(params || {})}`;

  window.Routes = {
    teacher_report_cards_pt_br_path: path('teacher_report_cards'),
    conceptual_exams_pt_br_path: path('conceptual_exams'),
    new_descriptive_exam_pt_br_path: path('new_descriptive_exam'),
    exam_record_report_classrooms_pt_br_path: path('exam_record_report_classrooms'),
    exam_record_report_disciplines_pt_br_path: path('exam_record_report_disciplines'),
    fetch_step_exam_record_report_pt_br_path: path('fetch_step_exam_record_report')
  };
}

function stubAjax() {
  const $ = window.jQuery;

  requests = [];

  $.ajax = function (options) {
    const deferred = $.Deferred();

    requests.push({ options: options, deferred: deferred });

    return deferred.promise();
  };
}

function respond(route, data) {
  const request = requests.find((candidate) => candidate.options.url.startsWith(`/${route}?`));

  request.options.success(data);
  request.deferred.resolve(data);
}

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const $ = (selector) => window.jQuery(selector);

async function changeClassroom(disciplines) {
  $('#exam_record_report_form_classroom_id').val('20').trigger('change');
  respond('fetch_step_exam_record_report', [{ id: 1, description: '1º Bimestre' }]);
  await flush();
  respond('exam_record_report_disciplines', { disciplines: disciplines });
}

beforeAll(async () => {
  loadIntoWindow(path.join(VENDOR_PATH, 'jquery.js'));
  loadIntoWindow(path.join(VENDOR_PATH, 'underscore.js'));

  // deixa o `ready` do jQuery resolver; a partir daqui os callbacks rodam na hora
  await flush();
});

beforeEach(() => {
  document.body.innerHTML = formHtml();
  stubGlobals();
  stubPlugins();
  stubAjax();
  window.eval(scriptSource);
});

describe('classroom change', () => {
  it('fetches the disciplines from the report action', async () => {
    await changeClassroom([{ id: 200, name: 'Matemática', text: 'Matemática' }]);

    const disciplinesRequest = requests.find((request) => request.options.url.includes('disciplines'));

    expect(disciplinesRequest.options.url).toBe('/exam_record_report_disciplines?classroom_id=20&format=json');
  });

  it('selects the discipline when it is the only one', async () => {
    await changeClassroom([{ id: 200, name: 'Matemática', text: 'Matemática' }]);

    expect($('#exam_record_report_form_discipline_id').val()).toBe('200');
  });

  it('leaves the discipline blank when there is more than one', async () => {
    const disciplines = [
      { id: 200, name: 'Ciências', text: 'Ciências' },
      { id: 201, name: 'Matemática', text: 'Matemática' }
    ];

    await changeClassroom(disciplines);

    expect($('#exam_record_report_form_discipline_id').val()).toBe('');
    expect($('#exam_record_report_form_discipline_id').data('options')).toEqual(disciplines);
  });
});

describe('unity change', () => {
  it('loads only the classrooms returned by the report action', () => {
    const classrooms = [{ id: 30, name: '5º ANO A', text: '5º ANO A' }];

    $('#exam_record_report_form_unity_id').val('2').trigger('change');
    respond('exam_record_report_classrooms', { classrooms: classrooms });

    expect($('#exam_record_report_form_classroom_id').data('options')).toEqual(classrooms);
  });
});
