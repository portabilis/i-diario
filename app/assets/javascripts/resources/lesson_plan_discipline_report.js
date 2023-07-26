$(function () {
  window.classrooms = [];
  window.disciplines = [];

  var $hideWhenGlobalAbsence = $(".hide-when-global-absence"),
    $globalAbsence = $("#discipline_lesson_plan_report_form_global_absence"),
    $examRuleNotFoundAlert = $('#exam-rule-not-found-alert')

  var fetchDisciplines = function (params, callback) {
    if (_.isEmpty(window.disciplines)) {
      $.getJSON('/disciplinas?' + $.param(params)).always(function (data) {
        window.disciplines = data;
        callback(window.disciplines);
      });
    } else {
      callback(window.disciplines);
    }
  };

  var fetchExamRule = function (params, callback) {
    $.getJSON('/exam_rules?' + $.param(params)).always(function (data) {
      callback(data);
    });
  };

  var $classroom = $('#discipline_lesson_plan_report_form_classroom_id');
  var $discipline = $('#discipline_lesson_plan_report_form_discipline_id');

  var checkExamRule = function (params) {
    fetchExamRule(params, function (exam_rule) {
      $('form input[type=submit]').removeClass('disabled');
      if (!$.isEmptyObject(exam_rule)) {
        $examRuleNotFoundAlert.addClass('hidden');

        if (exam_rule.frequency_type == 1) {
          $globalAbsence.val(1);
          $hideWhenGlobalAbsence.hide();
        } else {
          $globalAbsence.val(0);
          $hideWhenGlobalAbsence.show();
        }
      } else {
        $globalAbsence.val(0);
        $hideWhenGlobalAbsence.hide();

        // Display alert
        $examRuleNotFoundAlert.removeClass('hidden');

        // Disable form submit
        $('form input[type=submit]').addClass('disabled');
      }
    });
  }

  $classroom.on('change', function (e) {
    var params = {
      classroom_id: e.val
    };

    window.disciplines = [];
    $discipline.val('').select2({ data: [] });

    if (!_.isEmpty(e.val)) {
      checkExamRule(params);

      fetchDisciplines(params, function (disciplines) {
        var selectedDisciplines = _.map(disciplines, function (discipline) {
          return { id: discipline['id'], text: discipline['description'] };
        });

        $discipline.select2({
          data: selectedDisciplines
        });
      });
    }
  });

  if ($classroom.length && $classroom.val().length) {
    checkExamRule({ classroom_id: $classroom.val() });
  }
});
