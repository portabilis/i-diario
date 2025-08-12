$(function () {
  'use strict';

  var flashMessages = new FlashMessages();
  var $classroom = $("#filter_by_classroom_id");
  var $student = $("#filter_by_student_id");
  var $step = $("#filter_by_step");

  function setupSelect2(field, data, message) {
    var options = { data: data };
    if (message) {
      options.formatNoMatches = function() { return message; };
    }

    field.empty().val(null).trigger('change');
    field.select2(options);
  }

  async function fetchStudents(classroom_id) {
    return $.ajax({
      url: Routes.fetch_students_by_classroom_conceptual_exams_pt_br_path({
        classroom_id: classroom_id,
        format: "json"
      }),
      success: handleFetchStudentsSuccess,
      error: handleFetchStudentsError
    });
  }

  function handleFetchStudentsSuccess(students) {
    var studentOptions = _.map(students, function(student) {
      return { id: student.id, text: student.name };
    });

    studentOptions.unshift({ id: '', text: '' });

    setupSelect2($student, studentOptions);
  }

  function handleFetchStudentsError() {
    flashMessages.error("Ocorreu um erro ao buscar os alunos da turma selecionada.");
  }

  async function fetchSteps(classroom_id) {
    return $.ajax({
      url: Routes.find_step_number_by_classroom_conceptual_exams_pt_br_path({
        classroom_id: classroom_id,
        format: "json"
      }),
      success: handleFetchStepsSuccess,
      error: handleFetchStepsError
    });
  }

  function handleFetchStepsSuccess(steps) {
    var stepOptions = _.map(steps, function(step) {
      return { id: step.id, text: step.description };
    });

    stepOptions.unshift({ id: '', text: '' });

    setupSelect2($step, stepOptions);
  }

  function handleFetchStepsError() {
    flashMessages.error("Ocorreu um erro ao buscar as etapas da turma selecionada.");
  }

  function setupEmptyFields() {
    setupSelect2($student, [], 'Selecione uma turma para carregar os alunos');
    setupSelect2($step, [], 'Selecione uma turma para carregar as etapas');
  }

  $classroom.on("change", async function () {
    var classroom_id = $(this).val();

    if (classroom_id) {
      await fetchStudents(classroom_id);
      await fetchSteps(classroom_id);
    } else {
      setupEmptyFields();
    }
  });

  if ($classroom.val()) {
    fetchStudents($classroom.val());
    fetchSteps($classroom.val());
  }
});
