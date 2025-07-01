$(function () {
  window.classrooms = [];
  window.disciplines = [];

  var $hideWhenGlobalAbsence = $(".hide-when-global-absence"),
      $globalAbsence = $("#knowledge_area_lesson_plan_report_form_global_absence"),
      $examRuleNotFoundAlert = $('#exam-rule-not-found-alert'),
      $showKnowledge_area = $(".show_knowledge_area");

  var fetchClassrooms = function (params, callback) {
    if (_.isEmpty(window.classrooms)) {
      $.getJSON(Routes.classrooms_pt_br_path(params)).always(function (data) {
        window.classrooms = data;
        callback(window.classrooms);
      });
    } else {
      callback(window.classrooms);
    }
  };

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

  var $unity = $('#knowledge_area_lesson_plan_report_form_unity_id');
  var $classroom = $('#knowledge_area_lesson_plan_report_form_classroom_id');
  var $discipline = $('#knowledge_area_lesson_plan_report_form_discipline_id');

  $unity.on('change', function (e) {
    var params = {
      filter: {
        by_unity: e.val
      },
      find_by_current_teacher: true
    };

    window.classrooms = [];
    window.disciplines = [];

    $classroom.val('').select2({ data: [] });
    $discipline.val('').select2({ data: [] });
    $('#knowledge_area_lesson_plan_report_form_class_numbers').select2("val", "")

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
      if(!$.isEmptyObject(exam_rule)){
        $examRuleNotFoundAlert.addClass('hidden');

        if(exam_rule.frequency_type == 1){
          $globalAbsence.val(1);
          $hideWhenGlobalAbsence.hide();
          $showKnowledge_area.show();
        }else{
          $globalAbsence.val(0);
          $hideWhenGlobalAbsence.show();
          $showKnowledge_area.hide();
        }
      }else{
        $globalAbsence.val(0);
        $hideWhenGlobalAbsence.hide();
        $showKnowledge_area.show();

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
    $('#knowledge_area_lesson_plan_report_form_class_numbers').select2("val", "")


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

  $hideWhenGlobalAbsence.hide();
  $showKnowledge_area.hide();

  if ($classroom.length && $classroom.val().length){
    checkExamRule({classroom_id: $classroom.val()});
  }
});
