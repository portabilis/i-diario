$(function () {
  'use strict';

  var flashMessages = new FlashMessages();
  var $classroom = $('#observation_record_report_form_classroom_id');
  var $discipline = $('#observation_record_report_form_discipline_id');
  var $disciplineContainer = $('.observation_record_report_form_discipline_id');

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
  }

  function handleFetchDisciplinesSuccess(disciplines) {
    var selectedDisciplines = _.map(disciplines, function(discipline) {
      return { id: discipline['id'], text: discipline['description'] };
    });

    $discipline.select2({ data: selectedDisciplines });
  }

  function handleFetchDisciplinesError() {
    flashMessages.error('Ocorreu um erro ao buscar as disciplinas da turma selecionada.');
  }

  function fetchExamRule() {
    $disciplineContainer.hide();
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
    var examRule = data.exam_rule
    if (!$.isEmptyObject(examRule) && (examRule.frequency_type == '2' || examRule.allow_frequency_by_discipline)) {
      $disciplineContainer.show();
    } else {
      $disciplineContainer.hide();
      $discipline.select2('val', '');
    }
  };

  function handleFetchExamRuleError() {
    flashMessages.error('Ocorreu um erro ao buscar a regra de avaliação da turma selecionada.');
  };

  // On change

  $classroom.on('change', function() {
    fetchExamRule();
    fetchDisciplines();
  });

  fetchExamRule();
});
