$(function () {
  'use strict';

  var $opinionType = $('#descriptive_exam_opinion_type'),
      $discipline = $('#descriptive_exam_discipline_id'),
      $step = $('#descriptive_exam_step_id'),
      $disciplineContainer = $('[data-descriptive-exam-discipline-container]'),
      $stepContainer = $('[data-descriptive-exam-step-container]'),
      should_clear_discipline = true,
      should_clear_step = true,
      discipline_id = $discipline.val();

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

  $opinionType.on('change', function() {
    setFields();
  });

  setFields();
});
