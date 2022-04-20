$(function () {
  'use strict';

  let dateRegex = '^(?:(?:31(\\/)(?:0?[13578]|1[02]))\\1|(?:(?:29|30)(\\/)(?:0?[1,3-9]|1[0-2])\\2))(?:(?:1[6-9]|[2-9]\\d)?\\d{2})$|^(?:29(\\/)0?2\\3(?:(?:(?:1[6-9]|[2-9]\\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00))))$|^(?:0?[1-9]|1\\d|2[0-8])(\\/)(?:(?:0?[1-9])|(?:1[0-2]))\\4(?:(?:1[6-9]|[2-9]\\d)?\\d{2})$';
  let flashMessages = new FlashMessages();
  let examRule = null;
  let $unity = $('#avaliation_recovery_lowest_note_recovery_diary_record_attributes_unity_id');
  let $classroom = $('#avaliation_recovery_lowest_note_recovery_diary_record_attributes_classroom_id');
  let $discipline = $('#avaliation_recovery_lowest_note_recovery_diary_record_attributes_discipline_id');
  let $step = $('#avaliation_recovery_lowest_note_step_id');
  let $recorded_at = $('#avaliation_recovery_lowest_note_recorded_at');
  let $submitButton = $('input[type=submit]');

  function fetchExamRule() {
    let classroom_id = $classroom.select2('val');

    if (!_.isEmpty(classroom_id)) {
      $.ajax({
        url: Routes.exam_rules_pt_br_path({ classroom_id: classroom_id, format: 'json' }),
        success: handleFetchExamRuleSuccess,
        error: handleFetchExamRuleError
      });
    }
  }

  function handleFetchExamRuleSuccess(data) {
    examRule = data.exam_rule;

    if (!$.isEmptyObject(examRule) && examRule.recovery_type === 0) {
      flashMessages.error('A turma selecionada está configurada para não permitir o lançamento de recuperações de etapas.');
    } else {
      flashMessages.pop('');
    }
  }

  function handleFetchExamRuleError() {
    flashMessages.error('Ocorreu um erro ao buscar a regra de avaliação da turma selecionada.');
  }

  function fetchStudentsInRecovery() {
    let step_id = $step.select2('val');
    let recorded_at = $recorded_at.val();

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
  }

  function handleFetchStudentsInRecoverySuccess(data) {
    let students = data.students;

    if (!_.isEmpty(students)) {
      let element_counter = 0;
      hideNoItemMessage();

      $('#recovery-diary-record-students').empty();

      _.each(students, function(student) {
        let element_id = new Date().getTime() + element_counter++;
        buildStudentField(element_id, student);
      });

      loadDecimalMasks();
    } else {
      $recorded_at.val($recorded_at.data('oldDate'));

      flashMessages.error('Nenhum aluno encontrado.');
    }
  }

  $recorded_at.on('focusin', function(){
    $(this).data('oldDate', $(this).val());
  });

  function buildStudentField(element_id, student, index = null){
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

  function handleFetchStudentsInRecoveryError() {
    flashMessages.error('Ocorreu um erro ao buscar os alunos.');
  }

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
    if(_.isEmpty(data.daily_notes)){
      flashMessages.error('A turma selecionada não possui notas lançadas nesta etapa.');
    } else {
      flashMessages.pop('');
      fetchStudentsInRecovery();
    }
  }

  function handleFetchCheckPersistedDailyNoteError() {
    flashMessages.error('Ocorreu um erro ao buscar as notas lançadas para esta turma nesta etapa.');
  }

  function hideNoItemMessage() {
    $('.no_item_found').hide();
  }

  function loadDecimalMasks() {
    let numberOfDecimalPlaces = $('#recovery-diary-record-students').data('scale');
    $('.nested-fields input.decimal').inputmask('customDecimal', { digits: numberOfDecimalPlaces });
  }

  $step.on('change', function() {
    checkPersistedDailyNote();
  });

  $recorded_at.on('change', function() {
    checkPersistedDailyNote();
  });

  $submitButton.on('click', function() {
    $recorded_at.unbind();
  });

  fetchExamRule();
  loadDecimalMasks();
  checkPersistedDailyNote();
});
