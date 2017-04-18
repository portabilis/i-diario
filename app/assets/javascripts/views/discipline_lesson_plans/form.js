$(function () {
  'use strict';

  var flashMessages = new FlashMessages();
  var $classroom = $('#discipline_lesson_plan_lesson_plan_attributes_classroom_id');
  var $discipline = $('#discipline_lesson_plan_discipline_id');
  var $classes = $('#discipline_lesson_plan_classes');
  var $classes_div = $('.discipline_lesson_plan_classes');
  var $lesson_plan_attachment = $('#lesson_plan_attachment');

  $(".lesson_plan_attachment").on('change', onChangeFileElement);

  function onChangeFileElement(){
    // escopado para permitir arquivos menores que 3MB(3145728 bytes)
    if (this.files[0].size > 3145728) {
      $(".discipline_lesson_plan_lesson_plan_lesson_plan_attachments_attachment").find('span').remove();
      $(".discipline_lesson_plan_lesson_plan_lesson_plan_attachments_attachment").addClass("error");
      $(this).after('<span class="help-inline">tamanho máximo por arquivo: 3 MB</span>');
      $(this).val("");
    }else {
      $(".discipline_lesson_plan_lesson_plan_lesson_plan_attachments_attachment").removeClass("error");
      $(".discipline_lesson_plan_lesson_plan_lesson_plan_attachments_attachment").find('span').remove();
    }
  }

  $('#discipline_lesson_plan').on('cocoon:after-insert', function(e, item) {
    $(item).find('input.file').on('change', onChangeFileElement);
  });

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

  function handleFetchExamRuleSuccess(data) {
    var examRule = data.exam_rule
    if (!$.isEmptyObject(examRule) && examRule.frequency_type !== '1') {
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
