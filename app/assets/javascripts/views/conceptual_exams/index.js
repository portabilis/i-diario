$(function() {
  'use strict';

  var flashMessages = new FlashMessages();
  var $classroomFilter = $('#filter_by_classroom_id');
  var $stepFilter = $('#filter_by_step_id');
  var $studentFilter = $('.conceptual-exam-student-filter');

  function setupSelect2(field, data, message) {
    var options = { data: data };
    if (message) {
      options.formatNoMatches = function() { return message; };
    }

    field.empty().val(null);
    field.select2(options);
  }

  function fetchStudents(classroom_id) {
    return $.ajax({
      url: Routes.fetch_students_by_classroom_conceptual_exams_pt_br_path({
        classroom_id: classroom_id,
        format: 'json'
      }),
      success: handleFetchStudentsSuccess,
      error: handleFetchStudentsError
    });
  }

  function handleFetchStudentsSuccess(students) {
    var studentOptions = _.map(students, function(student) {
      return { id: student.id, text: student.name };
    });

    studentOptions.unshift({ id: 'empty', text: '' });

    setupSelect2($studentFilter, studentOptions);
  }

  function handleFetchStudentsError() {
    flashMessages.error('Ocorreu um erro ao buscar os alunos da turma selecionada.');
  }

  function setupEmptyFields() {
    setupSelect2($studentFilter, [], 'Selecione uma turma para carregar os alunos');
  }

  function isEmptyValue(value) {
    return !value || value === 'empty' || value === '';
  }

  function updateStepsFilter(classroomId) {
    if ($stepFilter.length === 0) {
      return;
    }

    var params = {};

    if (!isEmptyValue(classroomId)) {
      params.classroom_id = classroomId;
    }

    $.getJSON('/conceptual_exams/fetch_steps', params, function(data) {
      $stepFilter.select2('destroy');
      $stepFilter.data('elements', data);

      $stepFilter.select2({
        formatResult: function(el) {
          if (el.children) {
            return "<div class='select2-result-label'><strong>" + (el.text || el.name) + "</strong></div>";
          }
          return "<div class='select2-user-result'>" + (el.name || el.text) + "</div>";
        },
        formatSelection: function(el) {
          return "<div class='select2-user-result'>" + (el.text || el.name) + "</div>";
        },
        data: data,
        allowClear: true,
        theme: 'classic'
      });
    });
  }

  // Limpa o step antes do form ser serializado pelo index.js global
  $classroomFilter.on('select2-selecting select2-clearing', function() {
    if ($stepFilter.length > 0) {
      $stepFilter.val('');
    }
  });

  $classroomFilter.on('change', function(e) {
    var classroomId = isEmptyValue(e.val) ? '' : e.val;
    updateStepsFilter(classroomId);

    if (classroomId) {
      fetchStudents(classroomId);
    } else {
      setupEmptyFields();
    }
  });

  // Atualiza etapas agrupadas se nenhuma turma estiver selecionada
  if (isEmptyValue($classroomFilter.val())) {
    updateStepsFilter('');
  }

  // Carrega alunos se já houver turma selecionada
  if ($classroomFilter.val()) {
    fetchStudents($classroomFilter.val());
  }
});
