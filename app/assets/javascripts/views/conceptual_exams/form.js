$(function() {
  'use strict';

  var $unity = $('#conceptual_exam_unity');
  var $classroom = $('#conceptual_exam_classroom_id');
  var $school_calendar_step = $('#conceptual_exam_school_calendar_step_id');
  var $recorded_at = $('#conceptual_exam_recorded_at');
  var $student = $('#conceptual_exam_student_id');
  var $examRuleNotFoundAlert = $('#exam-rule-not-found-alert');
  var $examRuleNotAllowConcept = $('#exam-rule-not-allow-concept');

  function fetchClassrooms() {
    var unity_id = $unity.select2('val');

    $classroom.select2('val', '');
    $classroom.select2({ data: [] });

    if (!_.isEmpty(unity_id)) {
      $.ajax({
        url: Routes.classrooms_pt_br_path({ unity_id: unity_id, format: 'json' }),
        success: handleFetchClassroomsSuccess,
        error: handleFetchClassroomsError
      });
    }
  };

  function handleFetchClassroomsSuccess(classrooms) {
    var classrooms = _.map(classrooms, function(classroom) {
      return { id: classroom['id'], text: classroom['description'] };
    });

    $classroom.select2({ data: classrooms });
  };

  function handleFetchClassroomsError() {
    flashMessages.error('Ocorreu um erro ao buscar as turmas da escola selecionada.');
  };

  function fetchExamRule() {
    var classroom_id = $classroom.select2('val');

    window.examRule = null;
    window.roundingTableValues = null;

    if (!_.isEmpty(classroom_id)) {
      $.ajax({
        url: Routes.exam_rules_pt_br_path({ classroom_id: classroom_id, format: 'json' }),
        success: handleFetchExamRuleSuccess,
        error: handleFetchExamRuleError
      });
    }
  };

  function handleFetchExamRuleSuccess(data) {
    window.examRule = data.exam_rule;
    window.roundingTableValues = _.map(data.exam_rule.rounding_table.rounding_table_values, function(rounding_table_value) {
      return { id: rounding_table_value.value, text: rounding_table_value.label };
    });
  };

  function handleFetchExamRuleError() {
    flashMessages.error('Ocorreu um erro ao buscar a regra de avaliação da turma selecionada.');
  };

  function fetchStudents() {
    var classroom_id = $classroom.select2('val');
    var recorded_at = $recorded_at.val();

    $student.select2('val', '');
    $student.select2({ data: [] });

    if (!_.isEmpty(classroom_id) && !_.isEmpty(recorded_at)) {
      $.ajax({
        url: Routes.classroom_students_pt_br_path({ classroom_id: classroom_id, date: recorded_at, format: 'json' }),
        success: handleFetchStudentsSuccess,
        error: handleFetchStudentsError
      });
    }
  };

  function handleFetchStudentsSuccess(data) {
    var students = _.map(data['students'], function(student) {
      return { id: student['id'], text: student['name'] };
    });

    $student.select2({ data: students });
  };

  function handleFetchStudentsError() {
    flashMessages.error('Ocorreu um erro ao buscar os alunos da turma selecionada.');
  };

  function fetchDisciplines() {
    var classroom_id = $classroom.select2('val');

    if (!_.isEmpty(classroom_id)) {
      $.ajax({
        url: Routes.disciplines_pt_br_path({ classroom_id: classroom_id, format: 'json' }),
        success: handleFetchDisciplinesSuccess,
        error: handleFetchDisciplinesError
      });
    }
  };

  function handleFetchDisciplinesSuccess(disciplines) {
    if (!_.isEmpty(disciplines)) {
      hideNoItemMessage();

      var element_counter = 0;

      _.each(disciplines, function(discipline) {
        var element_id = new Date().getTime() + element_counter++

        var html = JST['templates/conceptual_exams/conceptual_exam_value_fields']({
            discipline_id: discipline.id,
            discipline_description: discipline.description,
            element_id: element_id
          });

        $('#conceptual_exam_values').append(html);
      });

      loadSelect2ForConceptualExamValues();
    }
  };

  function handleFetchDisciplinesError() {
    flashMessages.error('Ocorreu um erro ao buscar as disciplinas da turma selecionada.');
  };

  function loadSelect2ForConceptualExamValues() {
    _.each($('input.conceptual-exam-value-select2'), function(element) {
      $(element).select2({
        formatResult: function(el) {
          return "<div class='select2-user-result'>" + el.name + "</div>";
        },
        formatSelection: function(el) {
          return el.name;
        },
        data: $(element).data('elements')
      });

      $(element).select2({
        data: window.roundingTableValues
      });
    });
  }

  function removeDisciplines() {
    // Remove not persisted disciplines
    $('.nested-fields.dynamic').remove();

    // Hide persisted disciplines and sets _destroy = true
    $('.nested-fields.existing').hide();
    $('.nested-fields.existing [id$=_destroy]').val(true);

    showNoItemMessage();
  }

  function hideNoItemMessage() {
    $('.no_item_found').hide();
  }

  function showNoItemMessage() {
    if (!$('.nested-fields').is(":visible")) {
      $('.no_item_found').show();
    }
  }

  // On change

  $unity.on('change', function() {
    fetchClassrooms();
  });

  $classroom.on('change', function() {
    fetchExamRule();
    fetchStudents();
    removeDisciplines();
    fetchDisciplines();
  });

  $recorded_at.on('change', function() {
    fetchStudents();
  });


  // window.classrooms = [];
  // window.disciplines = [];
  //
  // var fetchClassrooms = function (params, callback) {
  //   if (_.isEmpty(window.classrooms)) {
  //     $.getJSON('/turmas?' + $.param(params)).always(function (data) {
  //       window.classrooms = data;
  //       callback(window.classrooms);
  //     });
  //   } else {
  //     callback(window.classrooms);
  //   }
  // };
  //
  // var fetchDisciplines = function (params, callback) {
  //   if (_.isEmpty(window.disciplines)) {
  //     $.getJSON('/disciplinas?' + $.param(params)).always(function (data) {
  //       window.disciplines = data;
  //       callback(window.disciplines);
  //     });
  //   } else {
  //     callback(window.disciplines);
  //   }
  // };
  //
  // var fetchExamRule = function (params, callback) {
  //   $.getJSON('/exam_rules?' + $.param(params)).always(function (data) {
  //     callback(data);
  //   });
  // };
  //
  // $unity.on('change', function (e) {
  //   var params = {
  //     unity_id: e.val
  //   };
  //
  //   window.classrooms = [];
  //   window.disciplines = [];
  //   $classroom.val('').select2({ data: [] });
  //   $discipline.val('').select2({ data: [] });
  //
  //   if (!_.isEmpty(e.val)) {
  //     fetchClassrooms(params, function (classrooms) {
  //       var selectedClassrooms = _.map(classrooms, function (classroom) {
  //         return { id:classroom['id'], text: classroom['description'] };
  //       });
  //
  //       $classroom.select2({
  //         data: selectedClassrooms
  //       });
  //     });
  //   }
  // });
  //
  // var checkExamRule = function(params){
  //   fetchExamRule(params, function(data){
  //     var examRule = data.exam_rule
  //     $('form input[type=submit]').removeClass('disabled');
  //     $examRuleNotFoundAlert.addClass('hidden');
  //     $examRuleNotAllowConcept.addClass('hidden');
  //
  //     if(!$.isEmptyObject(examRule)){
  //       if(examRule.score_type != "2"){
  //         // Display alert
  //         $examRuleNotAllowConcept.removeClass('hidden');
  //
  //         // Disable form submit
  //         $('form input[type=submit]').addClass('disabled');
  //       }
  //     }else{
  //       // Display alert
  //       $examRuleNotFoundAlert.removeClass('hidden');
  //
  //       // Disable form submit
  //       $('form input[type=submit]').addClass('disabled');
  //     }
  //   });
  // }
  //
  // $classroom.on('change', function (e) {
  //   var params = {
  //     classroom_id: e.val
  //   };
  //
  //   window.disciplines = [];
  //   $discipline.val('').select2({ data: [] });
  //
  //   if (!_.isEmpty(e.val)) {
  //     checkExamRule(params);
  //
  //     fetchDisciplines(params, function (disciplines) {
  //       var selectedDisciplines = _.map(disciplines, function (discipline) {
  //         return { id:discipline['id'], text: discipline['description'] };
  //       });
  //
  //       $discipline.select2({
  //         data: selectedDisciplines
  //       });
  //     });
  //   }
  // });
  //
  // if($classroom.length && $classroom.val().length){
  //   checkExamRule({classroom_id: $classroom.val()});
  // }
});
