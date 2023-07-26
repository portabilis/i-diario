$(function () {
  'use strict';

  let flashMessages = new FlashMessages();
  let examRule = null;
  let $unity = $('#avaliation_recovery_lowest_note_recovery_diary_record_attributes_unity_id');
  let $classroom = $('#avaliation_recovery_lowest_note_recovery_diary_record_attributes_classroom_id');
  let $discipline = $('#avaliation_recovery_lowest_note_recovery_diary_record_attributes_discipline_id');
  let $step = $('#avaliation_recovery_lowest_note_step_id');
  let $recorded_at = $('#avaliation_recovery_lowest_note_recorded_at');
  let $submitButton = $('input[type=submit]');

  window.disciplines = [];

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

  function fetchExamRule() {
    let classroom_id = $classroom.select2('val');

    if (_.isEmpty(classroom_id)) {
      flashMessages.error('É necessário selecionar uma turma.');
    } else {
      $.ajax({
        url: Routes.exam_rules_pt_br_path({ classroom_id: classroom_id, format: 'json' }),
        success: handleFetchExamRuleSuccess,
        error: handleFetchExamRuleError
      });
    }
  }

  function handleFetchExamRuleSuccess(data) {
    examRule = data.exam_rule;
  }

  function handleFetchExamRuleError() {
    flashMessages.error('Ocorreu um erro ao buscar a regra de avaliação da turma selecionada.');
  }

  $recorded_at.on('focusin', function () {
    $(this).data('oldDate', $(this).val());
  });

  function checkPersistedDailyNote() {
    let step_id = $step.select2('val');

    let filter = {
      by_classroom_id: $classroom.select2('val'),
      by_unity_id: $unity.select2('val'),
      by_discipline_id: $discipline.select2('val'),
      by_step_id: step_id,
      with_daily_note_students: true
    };

    if (!_.isEmpty(step_id)) {
      $.ajax({
        url: Routes.search_daily_notes_pt_br_path({ filter: filter, format: 'json' }),
        success: handleFetchCheckPersistedDailyNoteSuccess,
        error: handleFetchCheckPersistedDailyNoteError
      });
    }
  }

  function handleFetchCheckPersistedDailyNoteSuccess(data) {
    if (_.isEmpty(data.daily_notes)) {
      flashMessages.error('A turma selecionada não possui notas lançadas nesta etapa.');
    } else {
      flashMessages.pop('');
      let step_id = $step.select2('val');
      let recorded_at = $recorded_at.val();
      fetchStudents($classroom.select2('val'), $discipline.select2('val'), examRule, step_id, recorded_at);
    }
  }

  function fetchStudents(classroom, discipline, exam_rule, step_id, recorded_at) {
    if (_.isEmpty(step_id) || _.isEmpty(moment(recorded_at, 'MM-DD-YYYY')._i)) {
      return;
    }

    $.ajax({
      url: Routes.recovery_lowest_note_students_pt_br_path({
        classroom_id: classroom,
        discipline_id: discipline,
        step_id: step_id,
        date: recorded_at,
        format: 'json'
      }),
      success: studentInLowestNoteRecovery,
      error: handleFetchStudentsError
    });
  }

  function handleFetchStudentsError() {
    flashMessages.error('Ocorreu um erro ao buscar os alunos.');
  }

  function studentInLowestNoteRecovery(data) {
    let students = data.students;

    if (!_.isEmpty(students)) {
      let element_counter = 0;
      hideNoItemMessage();

      $('#recovery-diary-record-students').empty();

      _.each(students, function (student) {
        let element_id = new Date().getTime() + element_counter++;
        buildStudentField(element_id, student);
      });

      loadDecimalMasks();
    } else {
      $recorded_at.val($recorded_at.data('oldDate'));

      flashMessages.error('Nenhum aluno encontrado.');
    }

    function buildStudentField(element_id, student, index = null) {
      let html = JST['templates/avaliation_recovery_lowest_notes/student_fields']({
        id: student.id,
        name: student.name,
        lowest_note_in_step: student.lowest_note_in_step,
        scale: 2,
        element_id: element_id,
        exempted_from_discipline: student.exempted_from_discipline
      });

      let $tbody = $('#recovery-diary-record-students');

      if ($.isNumeric(index)) {
        $(html).insertAfter($tbody.children('tr')[index]);
      } else {
        $tbody.append(html);
      }
    }
  }

  function handleFetchCheckPersistedDailyNoteError() {
    flashMessages.error('Ocorreu um erro ao buscar as notas lançadas para esta turma nesta etapa.');
  }

  function checkExistsRecoveryLowestNoteOnStep() {
    let step_id = $step.select2('val');
    let classroom_id = $classroom.select2('val');
    let discipline_id = $discipline.select2('val');

    if (_.isEmpty(step_id)) {
      flashMessages.error('É necessário selecionar uma etapa.');
    } else {
      $.ajax({
        url: Routes.exists_recovery_on_step_avaliation_recovery_lowest_notes_pt_br_path({
          format: 'json',
          classroom_id: classroom_id,
          step_id: step_id,
          discipline_id: discipline_id
        }),
        success: handleFetchCheckExistsRecoveryLowestNoteOnStepSuccess,
        error: handleFetchCheckExistsRecoveryLowestNoteOnStepError
      });
    }
  }

  function handleFetchCheckExistsRecoveryLowestNoteOnStepSuccess(data) {
    if (data === true) {
      flashMessages.error('A turma selecionada já possui uma Recuperação de menor nota nesta etapa.');
    } else {
      flashMessages.pop('');
    }
  }

  function handleFetchCheckExistsRecoveryLowestNoteOnStepError() {
    flashMessages.error('Ocorreu um erro ao buscar as recuperações de menor nota da etapa');
  }

  function validDateOnStep() {
    let recorded_at = $recorded_at.val();
    let step_id = $step.select2('val');
    let classroom_id = $classroom.select2('val');

    $.ajax({
      url: Routes.recorded_at_in_selected_step_avaliation_recovery_lowest_notes_pt_br_path({
        format: 'json',
        classroom_id: classroom_id,
        step_id: step_id,
        recorded_at: recorded_at
      }),
      success: handleFetchRecordedAtOnStepSuccess,
      error: handleFetchRecordedAtOnStepError
    });
  }

  function handleFetchRecordedAtOnStepSuccess(data) {
    if (data === true) {
      flashMessages.pop('');
      checkPersistedDailyNote();
    } else {
      flashMessages.error('Data deve estar dentro da etapa selecionada');
    }
  }

  function handleFetchRecordedAtOnStepError() {
    flashMessages.error('Ocorreu um erro ao validar a data');
  }

  $step.on('change', checkExistsRecoveryLowestNoteOnStep);

  $recorded_at.on('change', validDateOnStep);

  $submitButton.on('click', function () {
    $recorded_at.unbind();
  });

  fetchExamRule();
  loadDecimalMasks();

  $classroom.on('change', async function (e) {
    await getExamSetting();
    await getStep();

    var params = {
      classroom_id: e.val
    };

    window.disciplines = [];

    if (!_.isEmpty(e.val)) {
      fetchDisciplines(params, function (disciplines) {
        var selectedDisciplines = _.map(disciplines, function (discipline) {
          return { id: discipline['id'], text: discipline['description'] };
        });

        $discipline.select2({
          data: selectedDisciplines
        });
        $recorded_at.val(null).trigger('change');
      });
    }
  });

  $discipline.on('change', function () {
    $recorded_at.val(null).trigger('change');
  });

  async function getStep() {
    let classroom_id = $classroom.select2('val');

    if (!_.isEmpty(classroom_id)) {
      return $.ajax({
        url: Routes.fetch_step_avaliation_recovery_lowest_notes_pt_br_path({
          classroom_id: classroom_id,
          format: 'json'
        }),
        success: handleFetchStepByClassroomSuccess,
        error: handleFetchStepByClassroomError
      });
    }
  }

  function handleFetchStepByClassroomSuccess(data) {
    let steps = data[0]
    // Define a primeira opção como selecionada por padrão
    $step.val(steps.id).trigger('change');
  };

  function handleFetchStepByClassroomError() {
    flashMessages.error('Ocorreu um erro ao buscar a etapa da turma.');
  };

  async function getExamSetting() {
    let classroom_id = $classroom.select2('val');

    if (!_.isEmpty(classroom_id)) {
      return $.ajax({
        url: Routes.fetch_exam_setting_arithmetic_avaliation_recovery_lowest_notes_pt_br_path({
          classroom_id: classroom_id,
          format: 'json'
        }),
        success: handleFetchExamSettingArithmeticByClassroomSuccess,
        error: handleFetchExamSettingArithmeticByClassroomError
      });
    }
  }

  function handleFetchExamSettingArithmeticByClassroomSuccess(data) {
    var readOnly = true;
    var successMessage = 'Configuração de avaliação validada com sucesso'
    var errorMessage = `A turma selecionada não está configurada com o tipo de cálculo de média compatível com o recurso.
    Para utilizar o mesmo, o tipo de cálculo deverá ser \'aritmético\'.`

    if (data === true) {
      readOnly = false;
      flashMessages.success(successMessage)
    } else {
      flashMessages.error(errorMessage);
    }

    $discipline.prop('readonly', readOnly);
    $step.prop('readonly', readOnly);
    $recorded_at.prop('readonly', readOnly);
  };

  function handleFetchExamSettingArithmeticByClassroomError() {
    flashMessages.error('É necessário configurar uma avaliação numérica');
    $discipline.prop('readonly', true);
    $step.prop('readonly', true);
  };

});
