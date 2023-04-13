$(document).ready(function() {
  'use strict';

  let flashMessages = new FlashMessages(),
      redirect_link_report_card = Routes.teacher_report_cards_pt_br_path(),
      redirect_link_conceptual_exams = Routes.conceptual_exams_pt_br_path(),
      redirect_link_descriptive_exams = Routes.new_descriptive_exam_pt_br_path(),
      message = `O <b>Registros de avaliações numéricas</b> apresentará somente as notas lançadas nos diários de avaliação e recuperações numéricas. Para conferência de notas conceituais e/ou descritivas acessar, respectivamente, o <a href="${redirect_link_report_card}"><b>Boletim do professor</b></a> ou as telas de <a href="${redirect_link_conceptual_exams}"><b>Diário de avaliações conceituais</b></a> e <a href="${redirect_link_descriptive_exams}"><b>Avaliações descritivas</b></a>.`;

  flashMessages.info(message);

  var $classroom = $('#exam_record_report_form_classroom_id');

  $classroom.on('change', async function () {
    await getStep();
  });

  async function getStep() {
    let classroom_id = $classroom.select2('val');

    if (!_.isEmpty(classroom_id)) {
      return $.ajax({
        url: Routes.fetch_step_exam_record_report_pt_br_path({
          classroom_id: classroom_id,
          format: 'json'
        }),
        success: handleFetchStepByClassroomSuccess,
        error: handleFetchStepByClassroomError
      });
    }
  }

  function handleFetchStepByClassroomSuccess(data) {
    let step = $('#exam_record_report_form_school_calendar_classroom_step_id');
    console.log('data', data);
    step.select2('val', data);
  };

  function handleFetchStepByClassroomError() {
    flashMessages.error('Ocorreu um erro ao buscar a etapa da turma.');
  };
});
