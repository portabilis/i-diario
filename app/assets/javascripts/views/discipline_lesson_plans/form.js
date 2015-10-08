$(function () {
  var disciplines = [];
  var $classroom = $('#discipline_lesson_plan_lesson_plan_attributes_classroom_id');
  var $discipline = $('#discipline_lesson_plan_discipline_id');

  var fetchDisciplines = function(params, callback) {
    if (_.isEmpty(disciplines)) {
      $.getJSON(Routes.disciplines_pt_br_path(params)).always(function(data) {
        disciplines = data;
        callback(disciplines);
      });
    } else {
      callback(disciplines);
    }
  };

  var fetchExamRule = function (params, callback) {
    $.getJSON('/exam_rules?' + $.param(params)).always(function (data) {
      callback(data);
    });
  };

  var checkExamRule = function(params) {
    fetchExamRule(params, function(exam_rule){
      if(!$.isEmptyObject(exam_rule)){
        if(exam_rule.frequency_type == 1){
          $('#discipline_lesson_plan_classes').select2('val', '');
          $('.discipline_lesson_plan_classes').hide();
        }else{
          $('.discipline_lesson_plan_classes').show();
        }
      }else{
        $('#discipline_lesson_plan_classes').select2('val', '');
        $('.discipline_lesson_plan_classes').hide()
      }
    });
  };

  var classroomChangeHandler = (function() {
    var params = {
          classroom_id: $classroom.select2('val'),
          format: 'json'
        };

    disciplines = [];

    if (_.isEmpty($classroom.select2('val'))) {
      $discipline.select2('val', '');
      $discipline.select2({
        data: []
      });
    } else {
      checkExamRule(params);
      fetchDisciplines(params, function(disciplines) {
        var selectedDisciplines = _.map(disciplines, function(discipline) {
          return { id: discipline['id'], text: discipline['description'] };
        });

        $discipline.select2({
          data: selectedDisciplines
        });
      });
    }
  });

  $classroom.on('change', classroomChangeHandler);
  classroomChangeHandler();



});
