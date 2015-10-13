$(function () {
  'use strict';

  var flashMessages = new FlashMessages();
  var $classroom = $('#discipline_lesson_plan_lesson_plan_attributes_classroom_id');
  var $discipline = $('#discipline_lesson_plan_discipline_id');
  var $classes = $('#discipline_lesson_plan_classes');
  var $classes_div = $('.discipline_lesson_plan_classes');

  function classroomChangeHandler() {
    var classroom_id = $classroom.select2('val');

    $discipline.select2('val', '');
    $discipline.select2({ data: [] });

    if (!_.isEmpty(classroom_id)) {
      fetchDisciplines(classroom_id);
      fetchExamRule(classroom_id);
    } else {
      $classes_div.hide();
      $classes.select2('val', '');
    }
  };

  $classroom.on('change', classroomChangeHandler);
  classroomChangeHandler();

  function fetchDisciplines(classroom_id) {
    $.ajax({
      url: Routes.disciplines_pt_br_path({ classroom_id: classroom_id, format: 'json' }),
      success: handleFetchDisciplinesSuccess,
      error: handleFetchDisciplinesError
    });
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

  function fetchExamRule(classroom_id) {
    $.ajax({
      url: Routes.exam_rules_pt_br_path({ classroom_id: classroom_id, format: 'json' }),
      success: handleFetchExamRuleSuccess,
      error: handleFetchExamRuleError
    });
  };

  function handleFetchExamRuleSuccess(exam_rule) {
    if (!$.isEmptyObject(exam_rule) && exam_rule.frequency_type !== '1') {
      $classes_div.show();
    } else {
      $classes_div.hide();
      $classes.select2('val', '');
    }
  };

  function handleFetchExamRuleError() {
    flashMessages.error('Ocorreu um erro ao buscar a regra de avaliação da turma selecionada.');
  };
});
