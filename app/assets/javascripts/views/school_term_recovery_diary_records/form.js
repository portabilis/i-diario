$(function () {
  'use strict';

  let flashMessages = new FlashMessages();
  let examRule = null;
  let $unity = $('#school_term_recovery_diary_record_recovery_diary_record_attributes_unity_id');
  let $classroom = $('#school_term_recovery_diary_record_recovery_diary_record_attributes_classroom_id');
  let $discipline = $('#school_term_recovery_diary_record_recovery_diary_record_attributes_discipline_id');
  let $step = $('#school_term_recovery_diary_record_step_id');
  let $recorded_at = $('#school_term_recovery_diary_record_recorded_at');
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
      fetchStudentsInRecovery($classroom.select2('val'), $discipline.select2('val'), examRule, step_id, recorded_at, studentInStepRecovery);
    }
  }

  function studentInStepRecovery(data) {
    let students = data.students;

    if (!_.isEmpty(students)) {
      let element_counter = 0;
      let existing_ids = [];
      let fetched_ids = [];

      hideNoItemMessage();

      $('#recovery-diary-record-students').children('tr').each(function () {
        if (!$(this).hasClass('destroy')){
          existing_ids.push(parseInt(this.id));
        }
      });
      existing_ids.shift();

      if (_.isEmpty(existing_ids)){
        _.each(students, function(student) {
          let element_id = new Date().getTime() + element_counter++;

          buildStudentField(element_id, student);
        });
        loadDecimalMasks();
      } else {
        $.each(students, function(index, student) {
          let fetched_id = student.id;

          fetched_ids.push(fetched_id);

          if ($.inArray(fetched_id, existing_ids) == -1) {
            if($('#' + fetched_id).length != 0 && $('#' + fetched_id).hasClass('destroy')) {
              restoreStudent(fetched_id);
            } else {
              let element_id = new Date().getTime() + element_counter++;

              buildStudentField(element_id, student, index);
            }
            existing_ids.push(fetched_id);
          }
        });

        loadDecimalMasks();

        _.each(existing_ids, function (existing_id) {
          if ($.inArray(existing_id, fetched_ids) == -1) {
            removeStudent(existing_id);
          }
        });
      }
    } else {
      $recorded_at.val($recorded_at.data('oldDate'));

      flashMessages.error('Nenhum aluno encontrado.');
    }

    function buildStudentField(element_id, student, index = null){
      let html = JST['templates/school_term_recovery_diary_records/student_fields']({
        id: student.id,
        name: student.name,
        average: student.average,
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

    function removeStudent(id){
      $('#' + id).hide();
      $('#' + id).addClass('destroy');
      $('.nested-fields#' + id + ' [id$=_destroy]').val(true);
    }

    function restoreStudent(id) {
      $('#' + id).show();
      $('#' + id).removeClass('destroy');
      $('.nested-fields#' + id + ' [id$=_destroy]').val(false);
    }
  }

  function handleFetchCheckPersistedDailyNoteError() {
    flashMessages.error('Ocorreu um erro ao buscar as notas lançadas para esta turma nesta etapa.');
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
