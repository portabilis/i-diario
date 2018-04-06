$(function () {

  var $unity = $('#descriptive_exam_unity'),
      $classroom = $('#descriptive_exam_classroom_id'),
      $opinionType = $('#descriptive_exam_opinion_type'),
      $discipline = $('#descriptive_exam_discipline_id'),
      $step = $('#descriptive_exam_school_calendar_step'),
      $opinionTypeContainer = $('[data-opinion-type-container]'),
      $disciplineContainer = $('[data-descriptive-exam-discipline-container]'),
      $stepContainer = $('[data-descriptive-exam-step-container]'),
      $examRuleNotFoundAlert = $('#exam-rule-not-found-alert'),
      $examRuleNotAllowDescriptiveExam = $('#exam-rule-not-allow-descriptive-exam');

  window.classrooms = [];
  window.disciplines = [];

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

  var fetchOpinionTypes = function (params, callback) {
    $.getJSON(Routes.opinion_types_descriptive_exams_pt_br_path(params)).always(function (data) {
      callback(data);
    });
  };

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

  var checkOpinionTypes = function(params){
    fetchOpinionTypes(params, function(opnion_types){
      var opinionTypes = opnion_types;
      $('form input[type=submit]').removeClass('disabled');
      $examRuleNotAllowDescriptiveExam.addClass('hidden');
      $opinionTypeContainer.addClass('hidden');

      if(!$.isEmptyObject(opinionTypes)){

        $opinionType.val(opinionTypes[0]['id']).select2({data: opinionTypes});

        if(opinionTypes.lenght > 1){
          $opinionTypeContainer.removeClass('hidden');
        }
        $opinionType.trigger('change');
      }else{
        // Display alert
        $examRuleNotAllowDescriptiveExam.removeClass('hidden');

        // Disable form submit
        $('form input[type=submit]').addClass('disabled');
      }
    });
  }

  $opinionType.on('change', function(){
    var opinionType = $opinionType.val();
    var should_clear_discipline = true;
    var should_clear_step = true;
    $disciplineContainer.addClass('hidden');
    $stepContainer.addClass('hidden');

    if($.inArray(opinionType, ["2", "3", "5", "6"]) >= 0){
      if($.inArray(opinionType, ["2", "5"]) >= 0){
        $disciplineContainer.removeClass('hidden');
        should_clear_discipline = false
      }

      if($.inArray(opinionType, ["2", "3"]) >= 0){
        $stepContainer.removeClass('hidden');
        should_clear_step = false
      }
    }
    if(should_clear_discipline){
      $discipline.val('');
    }

    if(should_clear_step){
      $step.val('');
    }
  });

  $classroom.on('change', function (e) {
    var params = {
      classroom_id: e.val
    };

    window.disciplines = [];
    $discipline.val('').select2({ data: [] });

    if (!_.isEmpty(e.val)) {

      checkOpinionTypes(params);

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
    checkOpinionTypes({classroom_id: $classroom.val()});
  }
});
