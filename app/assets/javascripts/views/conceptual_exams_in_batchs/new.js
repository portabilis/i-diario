$(function() {
  'use strict';
  const flashMessages = new FlashMessages();

  $('#conceptual_exam_classroom_id').on('change', function () {
    flashMessages.pop('');
    $('#conceptual_exam_step_id').select2('val', '');

    populateSteps();
  });

  function populateSteps() {
    let classroom_id = $('#conceptual_exam_classroom_id').select2('val');

    if (!_.isEmpty(classroom_id)) {
      $.ajax({
        url: Routes.get_steps_conceptual_exams_in_batchs_pt_br_path({
          classroom_id: classroom_id,
          format: 'json'
        }),
        success: handleFetchStepsSuccess,
        error: handleFetchStepsError
      });
    }
  }

  function handleFetchStepsSuccess(data) {
    let steps = _.map(data.conceptual_exams_in_batchs, function(step) {
      return { id: step.table.id, name: step.table.name, text: step.table.text };
    });

    $('#conceptual_exam_step_id').select2({ data: steps })
  }

  function handleFetchStepsError() {
    flashMessages.error('Ocorreu um erro ao buscar as etapas da turma.');
  }
});
