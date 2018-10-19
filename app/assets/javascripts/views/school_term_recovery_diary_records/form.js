$(function () {
  'use strict';

  // Regular expression for dd/mm/yyyy date including validation for leap year and more
  var dateRegex = '^(?:(?:31(\\/)(?:0?[13578]|1[02]))\\1|(?:(?:29|30)(\\/)(?:0?[1,3-9]|1[0-2])\\2))(?:(?:1[6-9]|[2-9]\\d)?\\d{2})$|^(?:29(\\/)0?2\\3(?:(?:(?:1[6-9]|[2-9]\\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00))))$|^(?:0?[1-9]|1\\d|2[0-8])(\\/)(?:(?:0?[1-9])|(?:1[0-2]))\\4(?:(?:1[6-9]|[2-9]\\d)?\\d{2})$';

  var flashMessages = new FlashMessages();
  var examRule = null;
  var $unity = $('#school_term_recovery_diary_record_recovery_diary_record_attributes_unity_id');
  var $classroom = $('#school_term_recovery_diary_record_recovery_diary_record_attributes_classroom_id');
  var $discipline = $('#school_term_recovery_diary_record_recovery_diary_record_attributes_discipline_id');
  var $step = $('#school_term_recovery_diary_record_step_id');
  var $recorded_at = $('#school_term_recovery_diary_record_recorded_at');
  var $submitButton = $('input[type=submit]');

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

  function fetchStudentsInRecovery() {
    var step_id = $step.select2('val');
    var recorded_at = $recorded_at.val();

    if (!_.isEmpty(step_id) && !_.isEmpty(recorded_at.match(dateRegex)) && examRule.recovery_type !== 0) {
      $.ajax({
        url: Routes.in_recovery_students_pt_br_path({
            classroom_id: $classroom.select2('val'),
            discipline_id: $discipline.select2('val'),
            step_id: step_id,
            date: recorded_at,
            format: 'json'
          }),
        success: handleFetchStudentsInRecoverySuccess,
        error: handleFetchStudentsInRecoveryError
      });
    }
  };

  function handleFetchStudentsInRecoverySuccess(data) {
    var students = data.students;

    if (!_.isEmpty(students)) {
      var element_counter = 0;
      var any_student_exempted_from_discipline = false;

      hideNoItemMessage();

      _.each(students, function(student) {
        var element_id = new Date().getTime() + element_counter++;

        var html = JST['templates/school_term_recovery_diary_records/student_fields']({
            id: student.id,
            name: student.name,
            average: student.average,
            scale: 2,
            element_id: element_id,
            exempted_from_discipline: student.exempted_from_discipline
          });

        if (student.exempted_from_discipline) {
          any_student_exempted_from_discipline = true;
        }

        $('#recovery-diary-record-students').append(html);
      });

      if (any_student_exempted_from_discipline) {
        $('.exempted_students_from_discipline_legend').removeClass('hidden');
      }

      loadDecimalMasks();
    }
  };

  function handleFetchStudentsInRecoveryError() {
    flashMessages.error('Ocorreu um erro ao buscar os alunos.');
  };

  function checkPersistedDailyNote() {
    var step_id = $step.select2('val');

    var filter = {
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
    $('.nested-fields.dynamic').remove();
    $('.nested-fields.existing').hide();
    $('.nested-fields.existing [id$=_destroy]').val(true);
    $('.exempted_students_from_discipline_legend').addClass('hidden');

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

  $step.on('change', function() {
    removeStudents();
    checkPersistedDailyNote();
  });

  $recorded_at.on('change', function() {
    removeStudents();
    checkPersistedDailyNote();
  });

  $submitButton.on('click', function() {
    $recorded_at.unbind();
  });

  fetchExamRule();
  loadDecimalMasks();
});
