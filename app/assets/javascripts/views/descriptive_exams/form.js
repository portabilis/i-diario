$(function () {
  'use strict';

  var $opinionType = $('#descriptive_exam_opinion_type'),
      $discipline = $('#descriptive_exam_discipline_id'),
      $step = $('#descriptive_exam_step_id'),
      $disciplineContainer = $('[data-descriptive-exam-discipline-container]'),
      $stepContainer = $('[data-descriptive-exam-step-container]'),
      should_clear_discipline = true,
      should_clear_step = true,
      discipline_id = $discipline.val(),
      view_btn = $('#view-btn');

  if ($opinionType.data('elements').length === 2) {
   $opinionType.attr('readonly', true)
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

  $opinionType.on('change', function() {
    setFields();
  });

  setFields();

  $step.on('change', function() {
    let step_id = $step.val(),
        discipline_id = $discipline.val(),
        opinion_type = $('#descriptive_exam_opinion_type').val();

    $.ajax({
      url: Routes.find_descriptive_exams_pt_br_path({
        discipline_id: discipline_id,
        step_id: step_id,
        opinion_type: opinion_type,
        format: 'json'
      }),
      success: function(descriptive_exam_id) {
        if (descriptive_exam_id === null || !$.isNumeric(descriptive_exam_id)) {
          view_btn.addClass('disabled');
          view_btn.attr('href', '');

          return;
        }

        view_btn.removeClass('disabled');
        view_btn.attr('href', Routes.descriptive_exam_pt_br_path(descriptive_exam_id))
      }
    });
  })
});
