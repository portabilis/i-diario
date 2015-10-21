$(function () {

  var $unity = $('#descriptive_exam_unity'),
      $classroom = $('#descriptive_exam_classroom_id'),
      $discipline = $('#descriptive_exam_discipline_id'),
      $step = $('#descriptive_exam_school_calendar_step'),
      $disciplineContainer = $('[data-descriptive-exam-discipline-container]'),
      $stepContainer = $('[data-descriptive-exam-step-container]'),
      $examRuleNotFoundAlert = $('#exam-rule-not-found-alert'),
      $examRuleNotAllowDescriptiveExam = $('#exam-rule-not-allow-descriptive-exam');

  window.classrooms = [];
  window.disciplines = [];

  var fetchClassrooms = function (params, callback) {
    if (_.isEmpty(window.classrooms)) {
      $.getJSON('/classrooms?' + $.param(params)).always(function (data) {
        window.classrooms = data;
        callback(window.classrooms);
      });
    } else {
      callback(window.classrooms);
    }
  };

  var fetchDisciplines = function (params, callback) {
    if (_.isEmpty(window.disciplines)) {
      $.getJSON('/disciplines?' + $.param(params)).always(function (data) {
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

  $unity.on('change', function (e) {
    var params = {
      unity_id: e.val
    };

    window.classrooms = [];
    window.disciplines = [];
    $classroom.val('').select2({ data: [] });
    $discipline.val('').select2({ data: [] });

    if (!_.isEmpty(e.val)) {
      fetchClassrooms(params, function (classrooms) {
        var selectedClassrooms = _.map(classrooms, function (classroom) {
          return { id:classroom['id'], text: classroom['description'] };
        });

        $classroom.select2({
          data: selectedClassrooms
        });
      });
    }
  });

  var checkExamRule = function(params){
    fetchExamRule(params, function(data){
      var examRule = data.exam_rule);
      $('form input[type=submit]').removeClass('disabled');
      $examRuleNotFoundAlert.addClass('hidden');
      $examRuleNotAllowDescriptiveExam.addClass('hidden');
      $disciplineContainer.addClass('hidden');
      $stepContainer.addClass('hidden');

      var should_clear_discipline = true;
      var should_clear_step = true;

      if(!$.isEmptyObject(examRule)){
        if($.inArray(examRule.opinion_type, ["2", "3", "5", "6"]) >= 0){
          if($.inArray(examRule.opinion_type, ["2", "5"]) >= 0){
            $disciplineContainer.removeClass('hidden');
            should_clear_discipline = false
          }

          if($.inArray(examRule.opinion_type, ["2", "3"]) >= 0){
            $stepContainer.removeClass('hidden');
            should_clear_step = false
          }

        }else{
          // Display alert
          $examRuleNotAllowDescriptiveExam.removeClass('hidden');

          // Disable form submit
          $('form input[type=submit]').addClass('disabled');
        }
      }else{
        // Display alert
        $examRuleNotFoundAlert.removeClass('hidden');

        // Disable form submit
        $('form input[type=submit]').addClass('disabled');
      }

      if(should_clear_discipline)
        $discipline.val('');

      if(should_clear_step)
        $step.val('');
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
          return { id:discipline['id'], text: discipline['description'] };
        });

        $discipline.select2({
          data: selectedDisciplines
        });
      });
    }
  });

  if($classroom.length && $classroom.val().length){
    checkExamRule({classroom_id: $classroom.val()});
  }
});
