$(function () {
  window.classrooms = [];
  window.disciplines = [];

  var $hideWhenGlobalAbsence = $(".hide-when-global-absence"),
      $globalAbsence = $("#attendance_record_report_form_global_absence"),
      $examRuleNotFoundAlert = $('#exam-rule-not-found-alert'),
      $selectAll***REMOVED*** = $('#select-all-classes'),
      $deselectAll***REMOVED*** = $('#deselect-all-classes');

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

  var $unity = $('#attendance_record_report_form_unity_id');
  var $classroom = $('#attendance_record_report_form_classroom_id');
  var $discipline = $('#attendance_record_report_form_discipline_id');
  var $class_numbers = $('#attendance_record_report_form_class_numbers');

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
    $('#attendance_record_report_form_class_numbers').select2("val", "")

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
      var examRule = data.exam_rule;
      $('form input[type=submit]').removeClass('disabled');
      if(!$.isEmptyObject(examRule)){
        $examRuleNotFoundAlert.addClass('hidden');
        if(examRule.frequency_type == 2 || examRule.allow_frequency_by_discipline){
          $globalAbsence.val(0);
          $hideWhenGlobalAbsence.show();
        }else{
          $globalAbsence.val(1);
          $hideWhenGlobalAbsence.hide();
        }

      }else{
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
    $('#attendance_record_report_form_class_numbers').select2("val", "")


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

  $selectAll***REMOVED***.on('click', function(){
    var allElements = $.parseJSON($("#attendance_record_report_form_class_numbers").attr('data-elements'));
    var joinedElements = "";

    $.each(allElements, function(index, element){
      joinedElements = joinedElements + element.name + ",";
    });

    $class_numbers.val(joinedElements);
    $class_numbers.trigger("change");

    $selectAll***REMOVED***.hide();
    $deselectAll***REMOVED***.show();
  });

  $deselectAll***REMOVED***.on('click', function(){

    $class_numbers.val("");
    $class_numbers.trigger("change");

    $selectAll***REMOVED***.show();
    $deselectAll***REMOVED***.hide();
  });

  $hideWhenGlobalAbsence.hide();

  if ($classroom.length && $classroom.val().length){
    checkExamRule({classroom_id: $classroom.val()});
  }
});
