$(function () {

  var $unity = $('#conceptual_exam_unity'),
      $classroom = $('#conceptual_exam_classroom_id'),
      $discipline = $('#conceptual_exam_discipline_id'),
      $examRuleNotFoundAlert = $('#exam-rule-not-found-alert'),
      $examRuleNotAllowConcept = $('#exam-rule-not-allow-concept');

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
    fetchExamRule(params, function(exam_rule){
      $('form input[type=submit]').removeClass('disabled');
      $examRuleNotFoundAlert.addClass('hidden');
      $examRuleNotAllowConcept.addClass('hidden');

      if(!$.isEmptyObject(exam_rule)){
        if(exam_rule.score_type != "2"){
          // Display alert
          $examRuleNotAllowConcept.removeClass('hidden');

          // Disable form submit
          $('form input[type=submit]').addClass('disabled');
        }
      }else{
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
