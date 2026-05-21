$(function() {
  "use strict";

  var $classroom = $("#conceptual_exam_classroom_id");
  var $step = $("#conceptual_exam_step_id");
  var $student = $("#conceptual_exam_student_id");
  var old_values = {};
  var flashMessages = new FlashMessages();

  $classroom.on("change", async function() {
    await getStep();
    await getDisciplineScoreTypes();
  });

  async function getStep() {
    let classroom_id = $("#conceptual_exam_classroom_id").select2("val");

    if (!_.isEmpty(classroom_id)) {
      return $.ajax({
        url: Routes.find_step_number_by_classroom_conceptual_exams_pt_br_path({
          classroom_id: classroom_id,
          format: "json"
        }),
        success: handleFetchStepByClassroomSuccess,
        error: handleFetchStepByClassroomError
      });
    }
  }

  function handleFetchStepByClassroomSuccess(data) {
    let selectedSteps = data.map(function(step) {
      return { id: step["id"], text: step["description"] };
    });
    $step.select2({ data: selectedSteps });
    // Define a primeira opção como selecionada por padrão
    $step.val(selectedSteps[0].id).trigger("change");
  }

  function handleFetchStepByClassroomError() {
    flashMessages.error("Ocorreu um erro ao buscar a etapa da turma.");
  }

  async function getDisciplineScoreTypes() {
    let classroom_id = $("#conceptual_exam_classroom_id").select2("val");

    if (!_.isEmpty(classroom_id)) {
      return $.ajax({
        url: Routes.fetch_score_type_conceptual_exams_pt_br_path({
          classroom_id: classroom_id,
          format: "json"
        }),
        success: handleFetchDisciplineScoreTypeByClassroomSuccess,
        error: handleFetchDisciplineScoreTypeByClassroomError
      });
    }
  }

  function handleFetchDisciplineScoreTypeByClassroomSuccess(data) {
    if (data) {
      flashMessages.error(
        "A disciplina selecionada não possui nota conceitual"
      );
    }
  }

  function handleFetchDisciplineScoreTypeByClassroomError() {
    flashMessages.error("Ocorreu um erro ao buscar a regra de avaliação");
  }

  function fetchExamRule() {
    var classroom_id = $classroom.select2("val");
    var student_id = $student.select2("val");

    window.examRule = null;
    window.roundingTableValues = null;

    if (!_.isEmpty(classroom_id) && !_.isEmpty(student_id)) {
      $.ajax({
        url: Routes.exam_rules_pt_br_path({
          classroom_id: classroom_id,
          student_id: student_id,
          format: "json"
        }),
        success: handleFetchExamRuleSuccess,
        error: handleFetchExamRuleError
      });
    }
  }

  function handleFetchExamRuleSuccess(data) {
    if (examRuleIsValid(data.exam_rule)) {
      if (!data.exam_rule.conceptual_rounding_table) {
        flashMessages.error(
          "A regra de avaliação não possui tabela de arredondamento vinculada."
        );
        return {};
      }
      window.examRule = data.exam_rule;

      window.roundingTableValues = _.map(
        data.exam_rule.conceptual_rounding_table.rounding_table_values,
        function(rounding_table_value) {
          return {
            id: rounding_table_value.value,
            text: rounding_table_value.to_s
          };
        }
      );
    }
  }

  function handleFetchExamRuleError() {
    flashMessages.error(
      "Ocorreu um erro ao buscar a regra de avaliação do aluno selecionado."
    );
  }

  function examRuleIsValid(examRule) {
    var correct_score_type =
      examRule.score_type == "2" || examRule.score_type == "3";

    if (correct_score_type) {
      return true;
    } else {
      flashMessages.error(
        "O aluno informado não possui uma regra de avaliação conceitual."
      );

      return false;
    }
  }

  function fetchStudents() {
    var classroom_id = $classroom.select2("val");
    var discipline_id = window.state.current_discipline.id;
    var step_id = $step.select2("val");
    var recorded_at = $("#conceptual_exam_recorded_at").val();

    window.studentPreviouslySelected = $student.select2("val");
    $student.select2("val", "");
    $student.select2({ data: [] });

    if (step_id) {
      $.when(
        $.get(
          Routes.step_school_calendars_pt_br_path({
            classroom_id: classroom_id,
            step_id: step_id,
            format: "json"
          })
        ).done(function() {
          var filter = {
            classroom: classroom_id,
            discipline: discipline_id,
            score_type: "concept",
            show_inactive: false,
            date: recorded_at
          };

          if (!_.isEmpty(classroom_id) && !_.isEmpty(recorded_at)) {
            $.ajax({
              url: Routes.by_date_student_enrollments_lists_pt_br_path({
                filter: filter,
                format: "json"
              }),
              success: handleFetchStudentsSuccess,
              error: handleFetchStudentsError
            });
          }
        })
      );
    }
  }

  function handleFetchStudentsSuccess(data) {
    var studentPreviouslySelectedExists = false;

    var students = _.map(data.student_enrollments_lists, function(
      student_enrollment
    ) {
      if (student_enrollment.student_id == window.studentPreviouslySelected) {
        studentPreviouslySelectedExists = true;
      }

      return {
        id: student_enrollment.student_id,
        // O 'text' deve ser apenas o nome puro — é por ele que o select2
        // filtra a busca digitada. As situações vão em atributos próprios.
        text: student_enrollment.student.name,
        in_active_search: student_enrollment.in_active_search,
        in_dependence: student_enrollment.in_dependence,
        inactive: student_enrollment.inactive_on_date
      };
    });

    $student.select2({
      data: students,
      formatResult: formatStudentOption,
      formatSelection: formatStudentOption
    });

    if (studentPreviouslySelectedExists) {
      $student.select2("val", window.studentPreviouslySelected);
      window.studentPreviouslySelected = null;
      $student.trigger("change");
    }
  }

  function handleFetchStudentsError() {
    flashMessages.error(
      "Ocorreu um erro ao buscar os alunos da turma selecionada."
    );
  }

  function formatStudentOption(student) {
    var html = _.escape(student.text);

    if (student.in_active_search) {
      html += renderStudentStatusBadge("active-search");
    }
    if (student.inactive) {
      html += renderStudentStatusBadge("inactive");
    }

    return html;
  }

  function fetchDisciplines() {
    var classroom_id = $classroom.select2("val");
    var step_id = $step.select2("val");
    var student_id = $student.select2("val");
    $(".old_step_column").remove();

    if (
      !_.isEmpty(classroom_id) &&
      !_.isEmpty(step_id) &&
      !_.isEmpty(student_id)
    ) {
      $.when(
        $.get(
          Routes.old_steps_conceptual_values_pt_br_path({
            classroom_id: classroom_id,
            student_id: student_id,
            step_id: step_id,
            format: "json"
          })
        ).done(function(data) {
          old_values = data.old_steps_conceptual_values;
          makeOldValuesHeader();
        })
      ).then(function() {
        $.ajax({
          url: Routes.disciplines_pt_br_path({
            classroom_id: classroom_id,
            step_id: step_id,
            conceptual: true,
            student_id: $student.select2("val"),
            format: "json"
          }),
          success: handleFetchDisciplinesSuccess,
          error: handleFetchDisciplinesError
        });
      });
    }
  }

  function setTableColspans(colspans) {
    $("#conceptual_exam_values_table [colspan]").each(function() {
      $(this).attr("colspan", colspans);
    });
  }

  function makeOldValuesHeader() {
    var $ths = [];
    $.each(old_values, function(key, value) {
      $ths.push(
        $("<th/>")
          .addClass("old_step_column")
          .text(old_values[key]["description"])
      );
    });
    setTableColspans($ths.length + 2);
    $("#conceptual_exam_values_table")
      .find("thead th:first")
      .after($ths);
  }

  function handleFetchDisciplinesSuccess(disciplines) {
    if (!_.isEmpty(disciplines)) {
      hideNoItemMessage();

      disciplines = _.chain(disciplines)
        .sortBy("description")
        .sortBy("sequence")
        .sortBy("knowledge_area_description")
        .sortBy("knowledge_area_sequence")
        .value();

      var element_counter = 0;
      var disciplinesGroupedByKnowledgeArea = _.groupBy(disciplines, function(
        discipline
      ) {
        return discipline.knowledge_area_description;
      });

      $("#conceptual_exam_values").html("");

      _.each(disciplinesGroupedByKnowledgeArea, function(
        disciplines,
        knowledge_area_sequence
      ) {
        var knowledge_area = disciplines[0].knowledge_area_description;
        var knowledgeAreaTableRowHtml =
          '<tr class="knowledge-area-table-row"><td class="knowledge-area-table-data" colspan="' +
          (2 + old_values.length) +
          '"><strong>' +
          knowledge_area +
          "</strong></td></tr>";
        $("#conceptual_exam_values").append(knowledgeAreaTableRowHtml);

        _.each(disciplines, function(discipline) {
          var element_id = new Date().getTime() + element_counter++;

          var html = JST[
            "templates/conceptual_exams/conceptual_exam_value_fields"
          ]({
            discipline_id: discipline.id,
            discipline_description: discipline.description,
            element_id: element_id,
            old_values: old_values
          });

          $("#conceptual_exam_values").append(html);
        });
      });

      loadSelect2ForConceptualExamValues();
      disableDisciplinesAccordingToExemptedDisciplines();
      markDependenceDisciplines();
    }
  }

  function handleFetchDisciplinesError() {
    flashMessages.error(
      "Ocorreu um erro ao buscar as disciplinas da turma selecionada."
    );
  }

  function loadSelect2ForConceptualExamValues() {
    _.each($("input.conceptual-exam-value-select2"), function(element) {
      $(element).select2({
        formatResult: function(el) {
          return "<div class='select2-user-result'>" + el.name + "</div>";
        },
        formatSelection: function(el) {
          return el.name;
        },
        data: $(element).data("elements")
      });

      if (!_.isEmpty(window.roundingTableValues)) {
        $(element).select2({
          data: window.roundingTableValues
        });
      }
    });
  }

  function updateConceptualLegend() {
    var hasExempted = $('#conceptual_exam_values .badge-status--exempted-from-discipline').length > 0;
    var hasDependence = $('#conceptual_exam_values .badge-status--dependence').length > 0;

    $('.exempted_students_from_discipline_legend').toggleClass('hidden', !hasExempted);
    $('.dependence_students_legend').toggleClass('hidden', !hasDependence);
    $('.student-status-legend').toggleClass('hidden', !(hasExempted || hasDependence));
  }

  function removeDisciplines() {
    $(".knowledge-area-table-row").remove();
    $(".nested-fields.dynamic").remove();
    $(".nested-fields.existing").hide();
    $(".nested-fields.existing [id$=_destroy]").val(true);
    $(".old_step_column").remove();
    setTableColspans(2);

    showNoItemMessage();
    updateConceptualLegend();
  }

  function hideNoItemMessage() {
    $(".no_item_found").hide();
  }

  function showNoItemMessage() {
    if (!$(".nested-fields").is(":visible")) {
      $(".no_item_found").show();
    }
  }

  function disableDisciplinesAccordingToExemptedDisciplines() {
    var step_id = $step.select2("val");
    var student_id = $student.select2("val");
    var classroom_id = $classroom.select2("val");

    if (!_.isEmpty(step_id) && !_.isEmpty(student_id)) {
      $.ajax({
        url: Routes.exempted_disciplines_conceptual_exams_pt_br_path({
          step_id: step_id,
          student_id: student_id,
          classroom_id: classroom_id,
          format: "json"
        }),
        success: disableDisciplinesAccordingToExemptedDisciplinesSuccess,
        error: disableDisciplinesAccordingToExemptedDisciplinesError
      });
    }
  }

  function disableDisciplinesAccordingToExemptedDisciplinesSuccess(data) {
    var exempted_disciplines = data.conceptual_exams;

    $("tr input[id$=discipline_id]").each(function() {
      var discipline_id = $(this).val();

      if (
        exempted_disciplines.filter(function(item) {
          return item.discipline_id == discipline_id;
        }).length > 0
      ) {
        var item = $(this).closest("tr");
        var description = item.find(".discipline_description");
        if (description.nextAll(".badge-status--exempted-from-discipline").length === 0) {
          description.after(renderStudentStatusBadge('exempted-from-discipline'));
        }
        item.find("input[id$=_value]").attr("readonly", "readonly");
        item.find("input[id$=_exempted_discipline]").val("true");
      }
    });

    updateConceptualLegend();
  }

  function disableDisciplinesAccordingToExemptedDisciplinesError() {
    flashMessages.error(
      "Ocorreu um erro ao buscar as disciplinas dispensadas."
    );
  }

  // Marca o badge de "Dependência" ao lado das disciplinas em que o aluno
  // selecionado cursa dependência. A nota permanece editável — o aluno em
  // dependência recebe nota normalmente na disciplina cursada.
  function markDependenceDisciplines() {
    var student_id = $student.select2("val");
    var classroom_id = $classroom.select2("val");

    if (_.isEmpty(student_id) || _.isEmpty(classroom_id)) { return; }

    $.ajax({
      url: Routes.dependence_disciplines_conceptual_exams_pt_br_path({
        student_id: student_id,
        classroom_id: classroom_id,
        format: "json"
      }),
      success: markDependenceDisciplinesSuccess,
      error: markDependenceDisciplinesError
    });
  }

  function markDependenceDisciplinesSuccess(data) {
    var dependence_ids = (data && data.discipline_ids) || [];

    $("tr input[id$=discipline_id]").each(function() {
      var discipline_id = parseInt($(this).val(), 10);

      if (dependence_ids.indexOf(discipline_id) === -1) { return; }

      var item = $(this).closest("tr");
      var description = item.find(".discipline_description");

      if (description.nextAll(".badge-status--dependence").length === 0) {
        description.after(renderStudentStatusBadge('dependence'));
      }
    });

    updateConceptualLegend();
  }

  function markDependenceDisciplinesError() {
    flashMessages.error(
      "Ocorreu um erro ao buscar as disciplinas em dependência."
    );
  }

  function exists_conceptual_exam(conceptual_exam_id) {
    removeDisciplines();
    let text_step = $step
      .closest("div")
      .find("#s2id_conceptual_exam_step_id")
      .find(".select2-choice")
      .text()
      .trim();
    let student_name = $student
      .closest("div")
      .find("#s2id_conceptual_exam_student_id")
      .find(".select2-choice")
      .text()
      .trim();
    let redirect_link = Routes.edit_conceptual_exam_pt_br_path(
      conceptual_exam_id
    );
    let message = `O(a) aluno(a) ${student_name} já possui uma avaliação conceitual na etapa ${text_step}, para modificar a mesma clique aqui <a href="${redirect_link}" style="color: white"><b>Avaliação</b></a>.`;
    $("#btn-save").attr("disabled", true);
    $("#btn-save-and-next").attr("disabled", true);

    flashMessages.error(message);
  }

  // Aluno em Busca Ativa ou Não enturmado não pode receber lançamentos: exibe a
  // mensagem, não carrega as disciplinas e desabilita os botões de salvar.
  function blockStudentForSituation(situation) {
    var studentData = $student.select2("data");
    var studentName = (studentData && studentData.text) || "";
    var messages = {
      active_search:
        `O(a) aluno(a) ${studentName} está em situação de Busca Ativa e não pode receber lançamentos.`,
      not_grouped:
        `O(a) aluno(a) ${studentName} não está enturmado(a) na turma nesta data e não pode receber lançamentos.`
    };

    removeDisciplines();
    $("#btn-save").attr("disabled", true);
    $("#btn-save-and-next").attr("disabled", true);
    flashMessages.error(messages[situation]);
  }

  $student.on("change", function() {
    var studentData = $student.select2("data");
    updateConceptualLegend();

    if (studentData && studentData.in_active_search) {
      return blockStudentForSituation("active_search");
    }
    if (studentData && studentData.inactive) {
      return blockStudentForSituation("not_grouped");
    }

    $.get(
      Routes.find_conceptual_exam_by_student_conceptual_exams_pt_br_path({
        conceptual_exam: {
          classroom_id: $classroom.select2("val"),
          student_id: $student.select2("val"),
          step_id: $step.select2("val"),
          format: "json"
        }
      })
    ).done(function(conceptual_exam_id) {
      flashMessages.pop("");
      if (conceptual_exam_id) {
        exists_conceptual_exam(conceptual_exam_id);
      } else {
        $("#btn-save").attr("disabled", false);
        $("#btn-save-and-next").attr("disabled", false);
        fetchExamRule();
        removeDisciplines();
        fetchDisciplines();
      }
    });
  });

  if ($("#current_action_").val() == "new") {
    $student.trigger("change");
  }

  $step.on("change", function() {
    fetchStudents();
    $student.select2("val", "");
    removeDisciplines();
  });

  fetchExamRule();

  $("#conceptual_exam_recorded_at").on("change", function() {
    fetchStudents();
  });

  $(document).on('select2-selecting', '.control-group.select2 input[type="hidden"]', function() {
    let $currentInput = $(this);
    let $selects = $('.control-group.select2 input[type="hidden"]').filter(function() {
      return $(this).closest('tr').is(':visible');
    });
    let currentIndex = $selects.index($currentInput);

    setTimeout(function() {
        let $nextInput = $selects.eq(currentIndex + 1);
        if ($nextInput.length) {
            $nextInput.select2('focus');
        }
    }, 100);
  });
});
