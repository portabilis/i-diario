$(function () {
  "use strict"

  var $classroom = $('#knowledge_area_lesson_plan_report_form_classroom_id'),
    $knowledge_area = $('#knowledge_area_lesson_plan_report_form_knowledge_area_id'),
    flashMessages = new FlashMessages();

  $classroom.on('change', async function () {
    var classroom_id = $classroom.select2('val');

    $knowledge_area.select2('val', '');
    $knowledge_area.select2({ data: [] });

    if (!_.isEmpty(classroom_id)) {
      fetchKnowledgeArea(classroom_id);
    } else {
      $knowledge_area.val('').trigger('change');
    }
  });

  function fetchKnowledgeArea(classroom_id) {
    $.ajax({
      url: Routes.fetch_knowledge_areas_knowledge_area_lesson_plan_report_pt_br_path({
        classroom_id: classroom_id,
        format: 'json'
      }),
      success: handleFetchKnowledgeAreaSuccess,
      error: handleFetchKnowledgeAreaError
    });
  };

  function handleFetchKnowledgeAreaSuccess(knowledge_area) {
    var selectedKnownledgeAreaSuccess = _.map(knowledge_area, function (knowledge_area) {
      return { id: knowledge_area['id'], text: knowledge_area['description'] };
    });

    $knowledge_area.select2({ data: selectedKnownledgeAreaSuccess });

    // Define a primeira opção como selecionada por padrão
    $knowledge_area.val(selectedKnownledgeAreaSuccess[0].id).trigger('change');
  };

  function handleFetchKnowledgeAreaError() {
    flashMessages.error('Ocorreu um erro ao buscar as áreas de conhecimento da turma selecionada.');
  };

  $('#lesson-plan-report').on('click', function (e) {
    e.preventDefault();
    $('#knowledge-area-lesson-plan-report-form').attr('action',
      Routes.knowledge_area_lesson_plan_report_pt_br_path()
    );
    $('#knowledge-area-lesson-plan-report-form').submit();
  });

  $('#content-record-report').on('click', function (e) {
    e.preventDefault();
    $('#knowledge-area-lesson-plan-report-form').attr('action',
      Routes.knowledge_area_content_record_report_pt_br_path()
    );
    $('#knowledge-area-lesson-plan-report-form').submit();
  });
});
