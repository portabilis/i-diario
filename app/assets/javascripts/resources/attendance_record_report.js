$(function () {
  window.classrooms = [];
  window.disciplines = [];
  const PERIOD_FULL = 4;

  var $hideWhenGlobalAbsence = $(".hide-when-global-absence"),
    $globalAbsence = $("#attendance_record_report_form_global_absence"),
    $unity = $("#attendance_record_report_form_unity_id"),
    $examRuleNotFoundAlert = $('#exam-rule-not-found-alert'),
    $selectAllClasses = $('#select-all-classes'),
    $deselectAllClasses = $('#deselect-all-classes'),
    $classroom = $('#attendance_record_report_form_classroom_id'),
    $discipline = $('#attendance_record_report_form_discipline_id'),
    $class_numbers = $('#attendance_record_report_form_class_numbers'),
    flashMessages = new FlashMessages();

  $unity.on('change', function () {
    clearFields();
    getClassrooms();
  });

  function getClassrooms() {
    const unity_id = $unity.select2('val');

    if (!_.isEmpty(unity_id)) {
      $.ajax({
        url: Routes.by_unity_classrooms_pt_br_path({
          unity_id: unity_id,
          format: 'json'
        }),
        success: handleFetchClassroomsSuccess,
        error: handleFetchClassroomsError
      });
    }
  }

  function handleFetchClassroomsSuccess(data) {
    if (data.classrooms.length == 0) {
      blockFields();
      flashMessages.error('Não há turmas para a unidade selecionada.')
      return;
    }

    let classrooms = _.map(data.classrooms, function (classroom) {
      return { id: classroom.table.id, name: classroom.table.name, text: classroom.table.text };
    });

    $classroom.prop('readonly', false);
    $classroom.select2({ data: classrooms })
    // Define a primeira opção como selecionada por padrão
    $classroom.val(classrooms[0].id).trigger('change');
  }

  function handleFetchClassroomsError() {
    flashMessages.error('Ocorreu um erro ao buscar as turmas da escola selecionada.');
  }

  $classroom.on('change', function () {
    let classroom_id = $classroom.select2('val');
    var params = {
      classroom_id: classroom_id
    };

    $class_numbers.select2("val", "")

    if (!_.isEmpty(params)) {
      $discipline.prop('readonly', false);
      checkExamRule(params);
      fetchDisciplines(classroom_id);
    }
  });

  var fetchExamRule = function (params, callback) {
    $.getJSON('/exam_rules?' + $.param(params)).always(function (data) {
      callback(data);
    });
  };

  var checkExamRule = function (params) {
    fetchExamRule(params, function (data) {
      var examRule = data.exam_rule;
      $('form input[type=submit]').removeClass('disabled');
      if (!$.isEmptyObject(examRule)) {
        $examRuleNotFoundAlert.addClass('hidden');
        if (examRule.frequency_type == 2 || examRule.allow_frequency_by_discipline) {
          $globalAbsence.val(0);
          $hideWhenGlobalAbsence.show();
        } else {
          $globalAbsence.val(1);
          $hideWhenGlobalAbsence.hide();
        }

      } else {
        $globalAbsence.val(0);
        $hideWhenGlobalAbsence.hide();

        // Display alert
        $examRuleNotFoundAlert.removeClass('hidden');

        // Disable form submit
        $('form input[type=submit]').addClass('disabled');
      }
    });
  }

  function fetchDisciplines(classroom_id) {
    if (_.isEmpty(window.disciplines)) {
      $.ajax({
        url: Routes.by_classroom_disciplines_pt_br_path({ classroom_id: classroom_id, format: 'json' }),
        success: handleFetchDisciplinesSuccess,
        error: handleFetchDisciplinesError
      });
    }
  };

  function handleFetchDisciplinesSuccess(data) {
    if (data.disciplines.length == 0) {
      blockFields();
      flashMessages.error('Não existem disciplinas para a turma selecionada.');
      return;
    } else {
      var selectedDisciplines = data.disciplines.map(function (discipline) {
        return { id: discipline.table.id, name: discipline.table.name, text: discipline.table.text };
      });

      $discipline.select2({ data: selectedDisciplines });
      // Define a primeira opção como selecionada por padrão
      $discipline.val(selectedDisciplines[0].id).trigger('change');
    }
  };

  function handleFetchDisciplinesError() {
    flashMessages.error('Ocorreu um erro ao buscar as disciplinas da turma selecionada.');
  };

  function clearFields() {
    $classroom.val('').select2({ data: [] });
    $discipline.val('').select2({ data: [] });
  }

  function blockFields() {
    $classroom.prop('readonly', true);
    $discipline.prop('readonly', true);
  }

  $discipline.on('change', async function () {
    $('#attendance_record_report_form_period').select2('val', '');
    await getPeriod();
  });

  async function getPeriod() {
    let classroom_id = $('#attendance_record_report_form_classroom_id').select2('val');
    let discipline_id = $('#attendance_record_report_form_discipline_id').select2('val');

    if (!_.isEmpty(classroom_id)) {
      return $.ajax({
        url: Routes.period_attendance_record_report_pt_br_path({
          classroom_id: classroom_id,
          discipline_id: discipline_id,
          format: 'json'
        }),
        success: handleFetchPeriodByClassroomSuccess,
        error: handleFetchPeriodByClassroomError
      });
    }
  }

  function handleFetchPeriodByClassroomSuccess(data) {
    let period = $('#attendance_record_report_form_period');

    if (data != PERIOD_FULL) {
      getNumberOfClasses();
      period.select2('val', data);
      period.attr('readonly', true)
    } else {
      period.attr('readonly', false)
    }
  };

  function handleFetchPeriodByClassroomError() {
    flashMessages.error('Ocorreu um erro ao buscar o período da turma.');
  };

  function getNumberOfClasses() {
    let classroom_id = $('#attendance_record_report_form_classroom_id').select2('val');

    $.ajax({
      url: Routes.number_of_classes_attendance_record_report_pt_br_path({
        classroom_id: classroom_id,
        format: 'json'
      }),
      success: handleFetchNumberOfClassesByClassroomSuccess,
      error: handleFetchNumberOfClassesByClassroomError
    });
  }

  function handleFetchNumberOfClassesByClassroomSuccess(data) {
    var elements = []

    for (let i = 1; i <= data; i++) {
      elements.push({ id: i, name: i, text: i })
    }

    $class_numbers.select2('data', elements);
  }

  function handleFetchNumberOfClassesByClassroomError() {
    flashMessages.error('Ocorreu um erro ao buscar os numeros de aula da turma.');
  }

  $selectAllClasses.on('click', function () {
    var allElements = $.parseJSON($("#attendance_record_report_form_class_numbers").attr('data-elements'));
    var joinedElements = "";

    $.each(allElements, function (index, element) {
      joinedElements = joinedElements + element.name + ",";
    });

    $class_numbers.val(joinedElements);
    $class_numbers.trigger("change");

    $selectAllClasses.hide();
    $deselectAllClasses.show();
  });

  $deselectAllClasses.on('click', function () {

    $class_numbers.val("");
    $class_numbers.trigger("change");

    $selectAllClasses.show();
    $deselectAllClasses.hide();
  });

  $hideWhenGlobalAbsence.hide();

  if ($classroom.length && $classroom.val().length) {
    checkExamRule({ classroom_id: $classroom.val() });
  }

  $('form').submit(function (event) {
    var tempoEspera = 2000;

    // Define um timeout para habilitar o botão após o tempo de espera
    setTimeout(function () {
      $('#send-form').prop('disabled', false);
    }, tempoEspera);
  });
});
