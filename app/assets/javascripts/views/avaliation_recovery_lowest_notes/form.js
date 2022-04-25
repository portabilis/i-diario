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

  $recorded_at.on('focusin', function(){
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
      console.log('passei aq');
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
      let step_id = $step.select2('val');
      let recorded_at = $recorded_at.val();
      fetchStudentsInRecovery($classroom.select2('val'), $discipline.select2('val'), examRule, step_id, recorded_at, studentInLowestNoteRecovery);
    }
  }

  function studentInLowestNoteRecovery(data) {
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
  }

  function handleFetchCheckPersistedDailyNoteError() {
    flashMessages.error('Ocorreu um erro ao buscar as notas lançadas para esta turma nesta etapa.');
  }

  function checkExistsRecoveryLowestNoteOnStep() {
    let step_id = $step.select2('val');
    let classroom_id = $classroom.select2('val');

    if (_.isEmpty(step_id)) {
    } else {
      $.ajax({
        url: Routes.exists_recovery_on_step_avaliation_recovery_lowest_notes_pt_br_path({
          format: 'json',
          classroom_id: classroom_id,
          step_id: step_id
        }),
        success: handleFetchCheckExistsRecoveryLowestNoteOnStepSuccess,
        error: handleFetchCheckExistsRecoveryLowestNoteOnStepError
      });
    }
  }

  function handleFetchCheckExistsRecoveryLowestNoteOnStepSuccess(data) {
    if (data === true) {
      flashMessages.error('A turma selecionada já possui uma Recuperação de menor nota nesta etapa.');
    }
  }

  function handleFetchCheckExistsRecoveryLowestNoteOnStepError() {
    flashMessages.error('Ocorreu um erro ao buscar as recuperações de menor nota da etapa');
  }

  $step.on('change', checkExistsRecoveryLowestNoteOnStep);

  $recorded_at.on('change', checkPersistedDailyNote);

  $submitButton.on('click', function() {
    $recorded_at.unbind();
  });

  fetchExamRule();
  loadDecimalMasks();
});
