$(function() {
  'use strict';

  var flashMessages = new FlashMessages();
  var $classroomFilter = $('#filter_by_classroom_id');
  var $studentFilter = $('.iep-student-filter');

  function isEmptyValue(value) {
    return !value || value === 'empty' || value === '';
  }

  function setupSelect2(field, data, message) {
    var options = {
      data: data,
      formatResult: function(el) {
        return "<div class='select2-user-result'>" + el.name + "</div>";
      },
      formatSelection: function(el) {
        if (el.text) {
          return "<div class='select2-user-result'>" + el.text + "</div>";
        } else {
          return "<div class='select2-user-result'>" + el.name + "</div>";
        }
      },
      allowClear: true,
      theme: 'classic'
    };

    if (message) {
      options.formatNoMatches = function() { return message; };
    }

    field.select2('destroy');
    field.select2(options);
  }

  function fetchStudents(classroomId) {
    if (isEmptyValue(classroomId)) {
      setupSelect2($studentFilter, [], 'Selecione uma turma para carregar os alunos');
      return;
    }

    $.ajax({
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
      return { id: student.id, name: student.name, text: student.name };
    });

    studentOptions.unshift({ id: 'empty', name: '<option></option>', text: '' });

    setupSelect2($studentFilter, studentOptions);
  }

  function handleFetchStudentsError() {
    // Em erro, esvazia o filtro para não deixar alunos da turma anterior selecionáveis.
    setupSelect2($studentFilter, [], 'Selecione uma turma para carregar os alunos');
    flashMessages.error('Ocorreu um erro ao buscar os alunos da turma selecionada.');
  }

  // Ao trocar/limpar a turma, zera o aluno antes de recarregar (evita submeter aluno de outra turma).
  $classroomFilter.on('select2-selecting select2-clearing', function() {
    $studentFilter.val('');
  });

  $classroomFilter.on('change', function(e) {
    fetchStudents(isEmptyValue(e.val) ? '' : e.val);
  });

  // Carrega os alunos se já houver turma selecionada ao abrir a tela.
  if ($classroomFilter.val()) {
    fetchStudents($classroomFilter.val());
  }
});
