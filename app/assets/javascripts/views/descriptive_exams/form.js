$(function () {
  'use strict';

  var $opinionType = $('#descriptive_exam_opinion_type'),
    $discipline = $('#descriptive_exam_discipline_id'),
    $step = $('#descriptive_exam_step_id'),
    $classroom_id = $('#descriptive_exam_classroom_id'),
    $disciplineContainer = $('[data-descriptive-exam-discipline-container]'),
    $stepContainer = $('[data-descriptive-exam-step-container]'),
    should_clear_discipline = true,
    should_clear_step = true,
    discipline_id = $discipline.val(),
    view_btn = $('#view-btn');

  if ($opinionType.data('elements').length === 2) {
    $opinionType.attr('readonly', true)
  }

  $classroom_id.on('change', async function () {
    await getOpinionType();
    await getStep();
    setFields()
  })

  async function getOpinionType() {
    let classroom_id = $('#descriptive_exam_classroom_id').select2('val');

    if (!_.isEmpty(classroom_id)) {
      return $.ajax({
        url: Routes.opinion_types_descriptive_exams_pt_br_path({
          classroom_id: classroom_id,
          format: 'json'
        }),
        success: handleFetchOpinionTypeByClassroomSuccess,
        error: handleFetchOpinionTypeByClassroomError
      });
    }
  }

  function handleFetchOpinionTypeByClassroomSuccess(data) {
    var opinion_type = $("#descriptive_exam_opinion_type");
    var first_opinion = data[0]['table']

    opinion_type.select2('data', first_opinion);
  }

  function handleFetchOpinionTypeByClassroomError() {
    flashMessages.error('Ocorreu um erro ao buscar o tipo de avaliação da turma.');
  }

  async function getStep() {
    let classroom_id = $('#descriptive_exam_classroom_id').select2('val');

    if (!_.isEmpty(classroom_id)) {
      return $.ajax({
        url: Routes.find_step_number_by_classroom_descriptive_exams_pt_br_path({
          classroom_id: classroom_id,
          format: 'json'
        }),
        success: handleFetchStepByClassroomSuccess,
        error: handleFetchStepByClassroomError,
      });
    }
  }

  function handleFetchStepByClassroomSuccess(data) {
    var step = $("#descriptive_exam_step");
    var first_step = data[0]['table']

    step.select2('data', first_step);
  }

  function handleFetchStepByClassroomError() {
    flashMessages.error('Ocorreu um erro ao buscar a etapa da turma.');
  }

  function setFields() {
    var opinionType = $opinionType.val();
    should_clear_discipline = true;
    should_clear_step = true;

    $disciplineContainer.addClass('hidden');
    $stepContainer.addClass('hidden');

    if ($.inArray(opinionType, ["2", "3", "5", "6"]) >= 0) {
      if ($.inArray(opinionType, ["2", "5"]) >= 0) {
        $disciplineContainer.removeClass('hidden');
        should_clear_discipline = false;
      }

      if ($.inArray(opinionType, ["2", "3"]) >= 0) {
        $stepContainer.removeClass('hidden');
        should_clear_step = false;
      }
    } else {
      $opinionType.val('');
      $step.select2('val', '');
    }

    if (should_clear_discipline) {
      $discipline.val('');
    } else {
      $discipline.val(discipline_id);
    }

    if (should_clear_step) {
      $step.val('');
    }
  }

  function validateExistingExams() {
    let step_id = $step.val(),
      discipline_id = $discipline.val(),
      classroom_id = $classroom_id.val(),
      opinion_type = $('#descriptive_exam_opinion_type').val();

    $.ajax({
      url: Routes.find_descriptive_exams_pt_br_path({
        discipline_id: discipline_id,
        classroom_id: classroom_id,
        step_id: step_id,
        opinion_type: opinion_type,
        format: 'json'
      }),
      success: function (descriptive_exam_id) {
        if (descriptive_exam_id === null || !$.isNumeric(descriptive_exam_id)) {
          view_btn.addClass('disabled');
          view_btn.attr('href', '');

          return;
        }

        view_btn.removeClass('disabled');
        view_btn.attr('href', Routes.descriptive_exam_pt_br_path(descriptive_exam_id))
      }
    });
  }

  $opinionType.on('change', function () {
    setFields();
    validateExistingExams();
  });

  setFields();

  $step.on('change', function () {
    validateExistingExams();
  })
});
