$(function() {
  'use strict';

  var $unity = $('#conceptual_exam_unity');
  var $classroom = $('#conceptual_exam_classroom_id');
  var $school_calendar_step = $('#conceptual_exam_school_calendar_step_id');
  var $recorded_at = $('#conceptual_exam_recorded_at');
  var $student = $('#conceptual_exam_student_id');
  var $examRuleNotFoundAlert = $('#exam-rule-not-found-alert');
  var $examRuleNotAllowConcept = $('#exam-rule-not-allow-concept');
  var flashMessages = new FlashMessages();

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
    if (examRuleIsValid(data.exam_rule)) {
      window.examRule = data.exam_rule;
      window.roundingTableValues = _.map(data.exam_rule.rounding_table.rounding_table_values, function(rounding_table_value) {
        return { id: rounding_table_value.value, text: rounding_table_value.to_s };
      });
    }
  };

  function handleFetchExamRuleError() {
    flashMessages.error('Ocorreu um erro ao buscar a regra de avaliação da turma selecionada.');
  };

  function examRuleIsValid(examRule) {
    if (examRule.score_type != '2') {
      flashMessages.error('A turma informada não possui uma regra de avaliação conceitual.');
      return false;
    } else {
      return true;
    }
  }

  function fetchStudents() {
    var classroom_id = $classroom.select2('val');
    var recorded_at = $recorded_at.val();

    window.studentPreviouslySelected = $student.select2('val');
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
    var studentPreviouslySelectedExists = false;

    var students = _.map(data.students, function(student) {
      if (student.id == window.studentPreviouslySelected) {
        studentPreviouslySelectedExists = true;
      }

      return { id: student.id, text: student.name };
    });

    $student.select2({ data: students });

    if (studentPreviouslySelectedExists) {
      $student.select2('val', window.studentPreviouslySelected);
      window.studentPreviouslySelected = null;
    }
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
    console.log(disciplines);
    if (!_.isEmpty(disciplines)) {
      hideNoItemMessage();

      disciplines.sort(function(a, b) {
        return a.knowledge_area_description.localeCompare(b.knowledge_area_description);
      });

      var element_counter = 0;
      var disciplines***REMOVED***edByKnowledgeArea = _.groupBy(disciplines, function(discipline) {
        return discipline.knowledge_area_description;
      });

      _.each(disciplines***REMOVED***edByKnowledgeArea, function(disciplines, knowledge_area_description) {
        var knowledgeAreaTableRowHtml = '<tr class="knowledge-area-table-row"><td class="knowledge-area-table-data" colspan="2"><strong>' + knowledge_area_description + '</strong></td></tr>';
        $('#conceptual_exam_values').append(knowledgeAreaTableRowHtml);

        _.each(disciplines, function(discipline) {
          var element_id = new Date().getTime() + element_counter++

          var html = JST['templates/conceptual_exams/conceptual_exam_value_fields']({
              discipline_id: discipline.id,
              discipline_description: discipline.description,
              element_id: element_id
            });

          $('#conceptual_exam_values').append(html);
        });
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

      if (!_.isEmpty(window.roundingTableValues)) {
        $(element).select2({
          data: window.roundingTableValues
        });
      }
    });
  }

  function removeDisciplines() {
    // Remove knowledge areas rows
    $('.knowledge-area-table-row').remove();

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

  if($('#current_action_').val() == 'new'){
    $classroom.trigger('change');
  }

  $recorded_at.on('change', function() {
    fetchStudents();
  });
});
