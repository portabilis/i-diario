$(function () {
  'use strict';

  var $classroom = $('#descriptive_exam_classroom_id'),
      $opinionType = $('#descriptive_exam_opinion_type'),
      $discipline = $('#descriptive_exam_discipline_id'),
      $step = $('#descriptive_exam_step_id'),
      $opinionTypeContainer = $('[data-opinion-type-container]'),
      $disciplineContainer = $('[data-descriptive-exam-discipline-container]'),
      $stepContainer = $('[data-descriptive-exam-step-container]'),
      $examRuleNotAllowDescriptiveExam = $('#exam-rule-not-allow-descriptive-exam');

  var fetchOpinionTypes = function (params, callback) {
    $.getJSON(Routes.opinion_types_descriptive_exams_pt_br_path(params)).always(function (data) {
      callback(data);
    });
  };

  var checkOpinionTypes = function(params) {
    fetchOpinionTypes(params, function(opnion_types) {
      var opinionTypes = opnion_types;

      $('form input[type=submit]').removeClass('disabled');
      $examRuleNotAllowDescriptiveExam.addClass('hidden');
      $opinionTypeContainer.addClass('hidden');

      if (!$.isEmptyObject(opinionTypes)) {

        $opinionType.val(opinionTypes[0]['id']).select2({data: opinionTypes});

        if (opinionTypes.lenght > 1) {
          $opinionTypeContainer.removeClass('hidden');
        }

        $opinionType.trigger('change');
      } else {
        $examRuleNotAllowDescriptiveExam.removeClass('hidden');
        $('form input[type=submit]').addClass('disabled');
      }
    });
  }

  $opinionType.on('change', function() {
    var opinionType = $opinionType.val();
    var should_clear_discipline = true;
    var should_clear_step = true;

    $disciplineContainer.addClass('hidden');
    $stepContainer.addClass('hidden');

    if ($.inArray(opinionType, ["2", "3", "5", "6"]) >= 0) {
      if ($.inArray(opinionType, ["2", "5"]) >= 0) {
        $disciplineContainer.removeClass('hidden');
        should_clear_discipline = false
      }

      if ($.inArray(opinionType, ["2", "3"]) >= 0) {
        $stepContainer.removeClass('hidden');
        should_clear_step = false
      }
    }

    if (should_clear_discipline) {
      $discipline.val('');
    }

    if (should_clear_step) {
      $step.val('');
    }
  });

  checkOpinionTypes({classroom_id: $classroom.val()});
});
