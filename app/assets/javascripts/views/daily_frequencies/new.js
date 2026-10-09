var DAILY_FREQUENCY_WEEKDAY_NAMES = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];

function dailyFrequencyWeekdayFor(ddmmyyyy) {
  var parts = (ddmmyyyy || '').split('/');
  if (parts.length !== 3) { return null; }

  var date = new Date(parseInt(parts[2], 10), parseInt(parts[1], 10) - 1, parseInt(parts[0], 10));
  if (isNaN(date.getTime())) { return null; }

  return DAILY_FREQUENCY_WEEKDAY_NAMES[date.getDay()];
}

// Puro (sem jQuery/DOM): decide quais aulas oferecer no campo "Aula" da tela
// de diário de frequência individual, a partir do quadro de aulas embutido
// na página. Turma sem quadro cadastrado: mantém a lista cheia de aulas do
// calendário letivo (comportamento de antes da feature). Turma com quadro:
// filtra pelas aulas que o professor logado realmente tem naquele dia da
// semana/componente — pode não ter nenhuma (emptyByBoard: true).
function computeClassNumbersData(params) {
  var allocations = (params && params.allocations) || [];
  var classroomIdsWithBoard = (params && params.classroomIdsWithBoard) || [];
  var allClassNumbersElements = (params && params.allClassNumbersElements) || [];
  var classroomId = params && params.classroomId;
  var disciplineId = params && params.disciplineId;
  var frequencyDate = params && params.frequencyDate;

  if (!classroomId || !frequencyDate) {
    return null;
  }

  var classroomIdNum = parseInt(classroomId, 10);
  var quadroAtivo = classroomIdsWithBoard.indexOf(classroomIdNum) !== -1;

  if (!quadroAtivo) {
    return { elements: allClassNumbersElements, emptyByBoard: false };
  }

  var weekday = dailyFrequencyWeekdayFor(frequencyDate);
  var disciplineIdNum = disciplineId ? parseInt(disciplineId, 10) : null;
  var lessonNumbers = [];

  allocations.forEach(function (allocation) {
    var matches = allocation.classroom_id === classroomIdNum &&
      allocation.weekday === weekday &&
      (!disciplineIdNum || allocation.discipline_id === disciplineIdNum);

    if (matches && lessonNumbers.indexOf(allocation.lesson_number) === -1) {
      lessonNumbers.push(allocation.lesson_number);
    }
  });

  lessonNumbers.sort(function (a, b) { return a - b; });

  // name/text precisam ser string: o formatResult padrão do select2 (usado
  // quando reabrimos o campo sem repassar as opções customizadas do
  // app/assets/javascripts/select2.js) chama text.toUpperCase() pra
  // destacar a busca — com um Number aí, quebra e trava o dropdown.
  var elements = lessonNumbers.map(function (number) {
    return { id: number, name: String(number), text: String(number) };
  });

  return { elements: elements, emptyByBoard: elements.length === 0 };
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    dailyFrequencyWeekdayFor: dailyFrequencyWeekdayFor,
    computeClassNumbersData: computeClassNumbersData
  };
}

// Guarda pro arquivo poder ser `require`ado nos testes Jest (sem jQuery no
// ambiente) só pelas funções puras acima — no navegador $ sempre existe.
if (typeof $ !== 'undefined') {
$(function () {
  window.classrooms = [];
  window.disciplines = [];
  window.avaliations = [];

  var $disciplineAbsenceFields = $(".discipline_absence_fields"),
      $globalAbsence = $("#daily_frequency_global_absence"),
      $examRuleNotFoundAlert = $('#exam-rule-not-found-alert');

  var fetchClassrooms = function (params, callback) {
    if (_.isEmpty(window.classrooms)) {
      $.getJSON(Routes.classrooms_pt_br_path(params)).always(function (data) {
        window.classrooms = data;
        callback(window.classrooms);
      });
    } else {
      callback(window.classrooms);
    }
  };

  var fetchDisciplines = function (params, callback) {
    if (_.isEmpty(window.disciplines)) {
      $.getJSON('/disciplinas?' + $.param(params)).always(function (data) {
        window.disciplines = data;
        callback(window.disciplines);
      });
    } else {
      callback(window.disciplines);
    }
  };

  var fetchAvaliations = function (params, callback) {
    if (_.isEmpty(window.avaliations)) {
      $.getJSON('/teacher_avaliations?' + $.param(params)).always(function (data) {
        window.avaliations = data;
        callback(window.avaliations);
      });
    } else {
      callback(window.avaliations);
    }
  };

  var fetchExamRule = function (params, callback) {
    $.getJSON('/exam_rules?' + $.param(params)).always(function (data) {
      callback(data);
    });
  };

  var $classroom          = $('#daily_frequency_classroom_id');
  var $discipline         = $('#daily_frequency_discipline_id');
  var $avaliation         = $('#daily_frequency_avaliation_id');
  var $frequencyDate      = $('#daily_frequency_frequency_date');
  var $classNumbers       = $('#class_numbers');
  var $classNumbersEmpty  = $('#class-numbers-empty-warning');

  // Aulas (turma/componente/dia da semana/nº) que o professor logado tem no
  // quadro de aulas, já embutidas na página — nenhuma chamada ao servidor
  // necessária pra filtrar, então a troca de data/turma/componente responde
  // na hora.
  var lessonsBoardAllocations = $classNumbers.data('lessons-board-allocations') || [];
  var classroomIdsWithBoard   = $classNumbers.data('classroom-ids-with-board') || [];
  var allClassNumbersElements = $classNumbers.data('elements') || [];

  // classroomId/disciplineId podem ser passados explicitamente porque, nos
  // handlers de 'change' do select2 (turma/componente), o valor mais
  // confiável no momento do evento é o `e.val` do próprio select2 — o
  // `.val()` do hidden input por trás pode não estar sincronizado ainda
  // (mesma convenção já usada nos outros handlers deste arquivo).
  var updateClassNumbers = function (classroomId, disciplineId) {
    classroomId = classroomId !== undefined ? classroomId : $classroom.val();
    disciplineId = disciplineId !== undefined ? disciplineId : $discipline.val();

    var result = computeClassNumbersData({
      allocations: lessonsBoardAllocations,
      classroomIdsWithBoard: classroomIdsWithBoard,
      allClassNumbersElements: allClassNumbersElements,
      classroomId: classroomId,
      disciplineId: disciplineId,
      frequencyDate: $frequencyDate.val()
    });

    if (!result) {
      return;
    }

    // Mesmas opções do inicializador global em select2.js — reinicializar só
    // com `data` perde formatResult/formatSelection/theme/allowClear e o
    // select2 cai no formatResult padrão (que quebra com valores não-string).
    $classNumbers.val('').select2({
      data: result.elements,
      multiple: true,
      formatResult: function (el) { return "<div class='select2-user-result'>" + el.name + "</div>"; },
      formatSelection: function (el) {
        var label = el.text || el.name;
        return "<div class='select2-user-result'>" + label + "</div>";
      },
      allowClear: true,
      theme: 'classic'
    });
    $classNumbers.select2('enable', !result.emptyByBoard);
    $classNumbersEmpty.toggleClass('hidden', !result.emptyByBoard);
  };

  $frequencyDate.on('change', function () { updateClassNumbers(); });


  $('#daily_frequency_unity_id').on('change', function (e) {
    var params = {
      filter: {
        by_unity: e.val
      },
      find_by_current_teacher: true
    };

    window.classrooms = [];
    window.disciplines = [];
    window.avaliations = [];
    $classroom.val('').select2({ data: [] });
    $discipline.val('').select2({ data: [] });
    $avaliation.val('').select2({ data: [] });

    if (!_.isEmpty(e.val)) {
      fetchClassrooms(params, function (classrooms) {
        var selectedClassrooms = _.map(classrooms, function (classroom) {
          return { id:classroom['id'], text: classroom['description'] };
        });

        $classroom.select2({
          data: selectedClassrooms
        });
      });
    }
  });

  var checkExamRule = function(params){
    fetchExamRule(params, function(data){
      var examRule = data.exam_rule;
      $('form input[type=submit]').removeClass('disabled');
      if(!$.isEmptyObject(examRule)){
        $examRuleNotFoundAlert.addClass('hidden');

        if(examRule.frequency_type == 2 || examRule.allow_frequency_by_discipline){
          $globalAbsence.val(0);
          $disciplineAbsenceFields.show();
        }else{
          $globalAbsence.val(1);
          $disciplineAbsenceFields.hide();
          $discipline.val('').select2({ data: [] })
        }

      }else{
        $globalAbsence.val(0);
        $disciplineAbsenceFields.hide();

        // Display alert
        $examRuleNotFoundAlert.removeClass('hidden');

        // Disable form submit
        $('form input[type=submit]').addClass('disabled');
      }
    });
  }

  $classroom.on('change', function (e) {
    var params = {
      classroom_id: e.val
    };

    window.disciplines = [];
    window.avaliations = [];
    $discipline.val('').select2({ data: [] });
    $avaliation.val('').select2({ data: [] });

    if (!_.isEmpty(e.val)) {

      checkExamRule(params);

      fetchDisciplines(params, function (disciplines) {
        var selectedDisciplines = _.map(disciplines, function (discipline) {
          return { id:discipline['id'], text: discipline['description'] };
        });

        $discipline.select2({
          data: selectedDisciplines
        });
      });
    }

    updateClassNumbers(e.val, '');
  });

  $('#daily_frequency_discipline_id').on('change', function (e) {
    updateClassNumbers($classroom.val(), e.val);

    var params = {
      discipline_id: e.val,
      classroom_id: $classroom.val()
    };

    window.avaliations = [];
    $avaliation.val('').select2({ data: [] });

    if (!_.isEmpty(e.val)) {
      fetchAvaliations(params, function (avaliations) {
        var selectedAvaliations = _.map(avaliations, function (avaliation) {
          return { id: avaliation['id'], text: avaliation['description'] };
        });

        $avaliation.select2({
          data: selectedAvaliations
        });
      });
    }
  });

  $disciplineAbsenceFields.hide();

  if($classroom.length && $classroom.val().length){
    checkExamRule({classroom_id: $classroom.val()});
  }

  updateClassNumbers();
});
}
