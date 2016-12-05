$(function () {
  'use strict';

  // Regular expression for dd/mm/yyyy date including validation for leap year and more
  var dateRegex = '^(?:(?:31(\\/)(?:0?[13578]|1[02]))\\1|(?:(?:29|30)(\\/)(?:0?[1,3-9]|1[0-2])\\2))(?:(?:1[6-9]|[2-9]\\d)?\\d{2})$|^(?:29(\\/)0?2\\3(?:(?:(?:1[6-9]|[2-9]\\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00))))$|^(?:0?[1-9]|1\\d|2[0-8])(\\/)(?:(?:0?[1-9])|(?:1[0-2]))\\4(?:(?:1[6-9]|[2-9]\\d)?\\d{2})$';

  var flashMessages = new FlashMessages();
  var examRule = null;
  var schoolCalendarStep = null;
  var $unity = $('#school_term_recovery_diary_record_recovery_diary_record_attributes_unity_id');
  var $classroom = $('#school_term_recovery_diary_record_recovery_diary_record_attributes_classroom_id');
  var $discipline = $('#school_term_recovery_diary_record_recovery_diary_record_attributes_discipline_id');
  var $school_calendar_classroom_step = $('#school_term_recovery_diary_record_school_calendar_classroom_step_id');
  var $recorded_at = $('#school_term_recovery_diary_record_recovery_diary_record_attributes_recorded_at');
  var $submitButton = $('input[type=submit]');


  function fetchDisciplines() {
    var classroom_id = $classroom.select2('val');

    $discipline.select2('val', '');
    $discipline.select2({ data: [] });

    if (!_.isEmpty(classroom_id)) {
      $.ajax({
        url: Routes.disciplines_pt_br_path({ classroom_id: classroom_id, format: 'json' }),
        success: handleFetchDisciplinesSuccess,
        error: handleFetchDisciplinesError
      });
    }
  };

  function handleFetchDisciplinesSuccess(disciplines) {
    var selectedDisciplines = _.map(disciplines, function(discipline) {
      return { id: discipline['id'], text: discipline['description'] };
    });

    $discipline.select2({ data: selectedDisciplines });
  };

  function handleFetchDisciplinesError() {
    flashMessages.error('Ocorreu um erro ao buscar as disciplinas da turma selecionada.');
  };

  function fetchExamRule() {
    var classroom_id = $classroom.select2('val');

    if (!_.isEmpty(classroom_id)) {
      $.ajax({
        url: Routes.exam_rules_pt_br_path({ classroom_id: classroom_id, format: 'json' }),
        success: handleFetchExamRuleSuccess,
        error: handleFetchExamRuleError
      });
    }
  };

  function handleFetchExamRuleSuccess(data) {
    examRule = data.exam_rule;
    if (!$.isEmptyObject(examRule) && examRule.recovery_type === 0) {
      flashMessages.error('A turma selecionada está configurada para não permitir o lançamento de recuperações de etapas.');
    } else {
      flashMessages.pop('');
    }
  };

  function handleFetchExamRuleError() {
    flashMessages.error('Ocorreu um erro ao buscar a regra de avaliação da turma selecionada.');
  };

  function fetchSchoolCalendarStep() {
    var school_calendar_classroom_step_id = $school_calendar_classroom_step.select2('val');

    if (!_.isEmpty(school_calendar_classroom_step_id)) {
      $.ajax({
        url: Routes.school_calendar_classroom_step_pt_br_path(school_calendar_classroom_step_id, { format: 'json' }),
        success: handleFetchSchoolCalendarStepSuccess,
        error: handleFetchSchoolCalendarStepError
      });
    }
  }

  function handleFetchSchoolCalendarStepSuccess(data) {
    schoolCalendarStep = data;
    console.log(schoolCalendarStep);
    loadDecimalMasks();
  };

  function handleFetchSchoolCalendarStepError() {
    flashMessages.error('Ocorreu um erro ao buscar a etapa selecionada.');
  };

  function fetchStudentsInRecovery() {
    var classroom_id = $classroom.select2('val');
    var discipline_id = $discipline.select2('val');
    var school_calendar_classroom_step_id = $school_calendar_classroom_step.select2('val');
    var recorded_at = $recorded_at.val();

    if (!_.isEmpty(classroom_id) &&
        !_.isEmpty(discipline_id) &&
        !_.isEmpty(school_calendar_classroom_step_id) &&
        !_.isEmpty(recorded_at.match(dateRegex)) &&
        examRule.recovery_type !== 0) {
      $.ajax({
        url: Routes.in_recovery_classroom_steps_students_pt_br_path({
            classroom_id: classroom_id,
            discipline_id: discipline_id,
            school_calendar_classroom_step_id: school_calendar_classroom_step_id,
            date: recorded_at,
            format: 'json'
          }),
        success: handleFetchStudentsInRecoverySuccess,
        error: handleFetchStudentsInRecoveryError
      });
      console.log(Routes.in_recovery_classroom_steps_students_pt_br_path({
          classroom_id: classroom_id,
          discipline_id: discipline_id,
          school_calendar_classroom_step_id: school_calendar_classroom_step_id,
          date: recorded_at,
          format: 'json'
        }));
    }
  };

  function handleFetchStudentsInRecoverySuccess(data) {
    var students = data.students
    if (!_.isEmpty(students)) {
      var element_counter = 0;

      hideNoItemMessage();

      _.each(students, function(student) {
        var element_id = new Date().getTime() + element_counter++

        var html = JST['templates/school_term_recovery_diary_records/student_fields']({
            id: student.id,
            name: student.name,
            average: student.average,
            scale: 2,
            element_id: element_id
          });

        $('#recovery-diary-record-students').append(html);
      });

      loadDecimalMasks();
    }
  };

  function handleFetchStudentsInRecoveryError() {
    flashMessages.error('Ocorreu um erro ao buscar os alunos.');
  };

  function checkPersistedDailyNote() {
    var unity_id = $unity.select2('val');
    var classroom_id = $classroom.select2('val');
    var discipline_id = $discipline.select2('val');
    var school_calendar_classroom_step_id = $school_calendar_classroom_step.select2('val');

    var filter = {
      by_classroom_id: classroom_id,
      by_unity_id: unity_id,
      by_discipline_id: discipline_id,
      by_school_calendar_classroom_step_id: school_calendar_classroom_step_id,
      with_daily_note_students: true
    };

    if (!_.isEmpty(school_calendar_classroom_step_id)) {
      $.ajax({
        url: Routes.search_daily_notes_pt_br_path({ filter: filter,
                                                    format: 'json' }),
        success: handleFetchCheckPersistedDailyNoteSuccess,
        error: handleFetchCheckPersistedDailyNoteError
      });
    }
  };

  function handleFetchCheckPersistedDailyNoteSuccess(data) {
    if(_.isEmpty(data.daily_notes)){
      flashMessages.error('A turma selecionada não possui notas lançadas nesta etapa.');
    } else {
      flashMessages.pop('');
      fetchStudentsInRecovery();
    }
  };

  function handleFetchCheckPersistedDailyNoteError() {
    flashMessages.error('Ocorreu um erro ao buscar as notas lançadas para esta turma nesta etapa.');
  };

  function removeStudents() {
    // Remove not persisted students
    $('.nested-fields.dynamic').remove();

    // Hide persisted students and sets _destroy = true
    $('.nested-fields.existing').hide();
    $('.nested-fields.existing [id$=_destroy]').val(true);

    showNoItemMessage();
  }

  function hideNoItemMessage() {
    $('.no_item_found').hide();
  }

  function showNoItemMessage() {
    if (!$('.nested-fields').is(":visible")) {
      $('.no_item_found').show();
    }
  }

  function loadDecimalMasks() {
    var numberOfDecimalPlaces = $('#recovery-diary-record-students').data('scale');
    $('.nested-fields input.decimal').inputmask('customDecimal', { digits: numberOfDecimalPlaces });
  }

  // On change

  $classroom.on('change', function() {
    fetchDisciplines();
    fetchExamRule();
    removeStudents();
  });

  $discipline.on('change', function() {
    removeStudents();
    checkPersistedDailyNote();
  });

  $school_calendar_classroom_step.on('change', function() {
    fetchSchoolCalendarStep();
    removeStudents();
    checkPersistedDailyNote();
  });

  $recorded_at.on('change', function() {
    removeStudents();
    checkPersistedDailyNote();
  });

  $submitButton.on('click', function() {
    // Workaround for a bug on Datepicker plugin to prevent change after submit
    $recorded_at.unbind();
  });

  // On load

  fetchExamRule();
  fetchSchoolCalendarStep();
  loadDecimalMasks();
});
