$(function() {
  'use strict';

  var $classroom = $('#conceptual_exam_classroom_id');
  var $step = $('#conceptual_exam_step_id');
  var $student = $('#conceptual_exam_student_id');
  var $discipline = $('#user_current_discipline_id');
  var flashMessages = new FlashMessages();

  function fetchExamRule() {
    var classroom_id = $classroom.select2('val');
    var student_id = $student.select2('val');

    window.examRule = null;
    window.roundingTableValues = null;

    if (!_.isEmpty(classroom_id) && !_.isEmpty(student_id)) {
      $.ajax({
        url: Routes.exam_rules_pt_br_path({
          classroom_id: classroom_id,
          student_id: student_id,
          format: 'json'
        }),
        success: handleFetchExamRuleSuccess,
        error: handleFetchExamRuleError
      });
    }
  };

  function handleFetchExamRuleSuccess(data) {
    if (examRuleIsValid(data.exam_rule)) {
      if (!data.exam_rule.conceptual_rounding_table) {
        flashMessages.error('A regra de avaliação não possui tabela de arredondamento vinculada.');
        return { }
      }
      window.examRule = data.exam_rule;

      window.roundingTableValues = _.map(data.exam_rule.conceptual_rounding_table.rounding_table_values, function(rounding_table_value) {
        return { id: rounding_table_value.value, text: rounding_table_value.to_s };
      });
    }
  };

  function handleFetchExamRuleError() {
    flashMessages.error('Ocorreu um erro ao buscar a regra de avaliação do aluno selecionado.');
  };

  function examRuleIsValid(examRule) {
    var correct_score_type = (examRule.score_type == '2' || examRule.score_type == '3')

    if (correct_score_type) {
      return true;
    } else {
      flashMessages.error('O aluno informado não possui uma regra de avaliação conceitual.');

      return false;
    }
  }

  function fetchStudents() {
    var classroom_id = $classroom.select2('val');
    var discipline_id = $discipline.select2('val');
    var step_id = $step.select2('val');
    var start_at = '';
    var end_at = '';

    window.studentPreviouslySelected = $student.select2('val');
    $student.select2('val', '');
    $student.select2({ data: [] });

    if (step_id) {
      $.when(
        $.get(
          Routes.step_school_calendars_pt_br_path({
            classroom_id: classroom_id,
            step_id: step_id,
            format: 'json'
          })
        ).done(function(data){
          start_at = data.start_at;
          end_at = data.end_at;
        })
      ).then(function() {
        var filter = {
          classroom: classroom_id,
          start_at: start_at,
          end_at: end_at,
          discipline: discipline_id,
          score_type: 'concept'
        };

        if (!_.isEmpty(classroom_id) && !_.isEmpty(start_at) && !_.isEmpty(end_at)) {
          $.ajax({
            url: Routes.by_date_range_student_enrollments_lists_pt_br_path({
              filter: filter,
              format: 'json'
            }),
            success: handleFetchStudentsSuccess,
            error: handleFetchStudentsError
          });
        }
      });
    }
  };

  function handleFetchStudentsSuccess(data) {
    var studentPreviouslySelectedExists = false;

    var students = _.map(data.student_enrollments_lists, function(student_enrollment) {
      if (student_enrollment.student_id == window.studentPreviouslySelected) {
        studentPreviouslySelectedExists = true;
      }

      return { id: student_enrollment.student_id, text: student_enrollment.student.name };
    });

    $student.select2({ data: students });

    if (studentPreviouslySelectedExists) {
      $student.select2('val', window.studentPreviouslySelected);
      window.studentPreviouslySelected = null;
      $student.trigger('change');
    }
  };

  function handleFetchStudentsError() {
    flashMessages.error('Ocorreu um erro ao buscar os alunos da turma selecionada.');
  };

  function fetchDisciplines() {
    var classroom_id = $classroom.select2('val');
    var step_id = $step.select2('val');

    if (!_.isEmpty(classroom_id) && !_.isEmpty(step_id)) {
      $.ajax({
        url: Routes.disciplines_pt_br_path(
          {
            classroom_id: classroom_id,
            step_id: step_id,
            conceptual: true,
            student_id: $student.select2('val'),
            format: 'json'
          }
        ),
        success: handleFetchDisciplinesSuccess,
        error: handleFetchDisciplinesError
      });
    }
  };

  function handleFetchDisciplinesSuccess(disciplines) {
    if (!_.isEmpty(disciplines)) {
      hideNoItemMessage();

      disciplines = _.sortBy(disciplines, function(discipline) {
        return [
          discipline.knowledge_area_sequence,
          discipline.knowledge_area_description,
          discipline.sequence,
          discipline.description
        ];
      });

      var element_counter = 0;
      var disciplines***REMOVED***edByKnowledgeArea = _.groupBy(disciplines, function(discipline) {
        return discipline.knowledge_area_description;
      });

      $('#conceptual_exam_values').html('');

      _.each(disciplines***REMOVED***edByKnowledgeArea, function(disciplines, knowledge_area_sequence) {
        var knowledge_area = disciplines[0].knowledge_area_description;
        var knowledgeAreaTableRowHtml = '<tr class="knowledge-area-table-row"><td class="knowledge-area-table-data" colspan="2"><strong>' +
                                        knowledge_area + '</strong></td></tr>';
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
      disableDisciplinesAccordingToExemptedDisciplines();
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
    $('.knowledge-area-table-row').remove();
    $('.nested-fields.dynamic').remove();
    $('.nested-fields.existing').hide();
    $('.nested-fields.existing [id$=_destroy]').val(true);
    $('.exempted_students_from_discipline_legend').addClass('hidden');

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

  function disableDisciplinesAccordingToExemptedDisciplines() {
    var step_id = $step.select2('val');
    var student_id = $student.select2('val');

    if (!_.isEmpty(step_id) && !_.isEmpty(student_id)) {
      $.ajax({
        url: Routes.exempted_disciplines_conceptual_exams_pt_br_path(
          {
            step_id: step_id,
            student_id: student_id,
            format: 'json'
          }
        ),
        success: disableDisciplinesAccordingToExemptedDisciplinesSuccess,
        error: disableDisciplinesAccordingToExemptedDisciplinesError
      });
    }
  }

  function disableDisciplinesAccordingToExemptedDisciplinesSuccess(data) {
    var exempted_disciplines = data.conceptual_exams;

    $('tr input[id$=discipline_id]').each(function() {
      var discipline_id = $(this).val();

      if(exempted_disciplines.filter(function(item) { return item.discipline_id == discipline_id }).length > 0) {
        var item = $(this).closest('tr');
        var description = item.find('.discipline_description');
        description.html('****' + description.html().trim());
        description.addClass('exempted-student-from-discipline');
        item.find('input[id$=_value]').attr('readonly','readonly');
        item.find('input[id$=_exempted_discipline]').val('true');
        $('.exempted_students_from_discipline_legend').removeClass('hidden');
      }
    });
  }

  function disableDisciplinesAccordingToExemptedDisciplinesError() {
    flashMessages.error('Ocorreu um erro ao buscar as disciplinas dispensadas.');
  };

  if($('#current_action_').val() == 'new'){
    $student.trigger('change');
  }

  $step.on('change', function() {
    fetchStudents();
    $student.select2('val', '');
    removeDisciplines();
  });

  $student.on('change', function(){
    fetchExamRule();
    removeDisciplines();
    fetchDisciplines();
  });

  fetchExamRule();
});
