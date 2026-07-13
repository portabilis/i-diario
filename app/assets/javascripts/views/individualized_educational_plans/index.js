$(function() {
  'use strict';

  var flashMessages = new FlashMessages();
  var $classroomFilter = $('#filter_by_classroom_id');
  var $studentFilter = $('.iep-student-filter');

  function setupSelect2(field, data, message) {
    var options = { data: data };
    if (message) {
      options.formatNoMatches = function() { return message; };
    }

    field.empty().val(null);
    field.select2(options);
  }

  function fetchStudents(classroomId) {
    return $.ajax({
      url: Routes.fetch_students_by_classroom_individualized_educational_plans_pt_br_path({
        classroom_id: classroomId,
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

  $classroomFilter.on('change', function(e) {
    var classroomId = isEmptyValue(e.val) ? '' : e.val;

    if (classroomId) {
      fetchStudents(classroomId);
    } else {
      setupEmptyFields();
    }
  });

  // Carrega os alunos se já houver turma selecionada ao abrir a tela
  if ($classroomFilter.val()) {
    fetchStudents($classroomFilter.val());
  } else {
    setupEmptyFields();
  }
});
