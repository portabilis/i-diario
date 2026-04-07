$(function () {
  'use strict';

  let flashMessages = new FlashMessages();
  let $unity = $('#observation_record_report_form_unity_id');
  let $classroom = $('#observation_record_report_form_classroom_id');
  let $discipline = $('#observation_record_report_form_discipline_id');
  let $teacher = $('#observation_record_report_form_teacher_id');
  let $student = $('#observation_record_report_form_student_id');
  var TEACHER_PLACEHOLDER = 'Selecione uma turma para filtrar por professor';
  var STUDENT_PLACEHOLDER = 'Selecione uma turma para filtrar por aluno';

  $(document).ready(function() {
    updateSubmitButton();
    getClassrooms();
    getDisciplines();
    getTeachers();
    getStudents();
  });

  $unity.on('change', function () {
    clearFields();
    getClassrooms();
    getDisciplines();
  });

  $classroom.on('change', function() {
    $discipline.val('').select2({ data: [] });
    resetTeacher();
    resetStudent();
    updateSubmitButton();
    getDisciplines();
    getTeachers();
    getStudents();
  });

  $discipline.on('change', function() {
    updateSubmitButton();
  });

  function updateSubmitButton() {
    var disciplineValue = $discipline.val();
    var hasDiscipline = disciplineValue !== '' && disciplineValue !== null;
    $('#btn-submit').prop('disabled', !hasDiscipline);
  }

  function getClassrooms() {
    const unity_id = $unity.select2('val');

    if (!_.isEmpty(unity_id)) {
      $.ajax({
        url: Routes.by_unity_classrooms_pt_br_path({
          unity_id: unity_id,
          format: 'json'
        }),
        success: handleFetchClassroomsSuccess,
        error: handleFetchClassroomsError
      });
    }
  }

  function handleFetchClassroomsSuccess(data) {
    let classrooms = _.map(data.classrooms, function(classroom) {
      return { id: classroom.table.id, name: classroom.table.name, text: classroom.table.text };
    });

    classrooms.unshift({ id: 'all', name: '<option>Todas</option>', text: 'Todas' });

    $classroom.select2({ data: classrooms })
  }

  function handleFetchClassroomsError() {
    flashMessages.error('Ocorreu um erro ao buscar as turmas da escola selecionada.');
  }

  function getDisciplines() {
    const classroom_id = $classroom.select2('val');
    const unity_id = $unity.select2('val');

    if (!_.isEmpty(classroom_id)) {
      $.ajax({
        url: Routes.observation_record_report_disciplines_pt_br_path({
          classroom_id: classroom_id,
          unity_id: unity_id,
          format: 'json'
        }),
        success: handleFetchDisciplinesSuccess,
        error: handleFetchDisciplinesError
      });
    }
  }

  function handleFetchDisciplinesSuccess(data) {
    let selectedDisciplines = _.map(data.disciplines, function(discipline) {
      return { id: discipline.id, name: discipline.name, text: discipline.text };
    });

    if (selectedDisciplines.length > 1) {
      selectedDisciplines.unshift({ id: 'all', name: '<option>Todas</option>', text: 'Todas' });
    }

    $discipline.select2({ data: selectedDisciplines });
    updateSubmitButton();
  }

  function handleFetchDisciplinesError() {
    flashMessages.error('Ocorreu um erro ao buscar as disciplinas da turma selecionada.');
  }

  function getTeachers() {
    const classroom_id = $classroom.select2('val');
    const unity_id = $unity.select2('val');

    if (!_.isEmpty(classroom_id) && classroom_id !== 'all') {
      $.ajax({
        url: Routes.observation_record_report_teachers_pt_br_path({
          classroom_id: classroom_id,
          unity_id: unity_id,
          format: 'json'
        }),
        success: handleFetchTeachersSuccess,
        error: handleFetchTeachersError
      });
    }
  }

  function handleFetchTeachersSuccess(data) {
    let teachers = _.map(data.teachers, function(teacher) {
      return { id: teacher.id, name: teacher.name, text: teacher.text };
    });

    teachers.unshift({ id: '', name: '', text: '' });
    $teacher.select2({ data: teachers });
  }

  function handleFetchTeachersError() {
    flashMessages.error('Ocorreu um erro ao buscar os professores.');
  }

  function getStudents() {
    const classroom_id = $classroom.select2('val');

    if (!_.isEmpty(classroom_id) && classroom_id !== 'all') {
      $.ajax({
        url: Routes.observation_record_report_students_pt_br_path({
          classroom_id: classroom_id,
          format: 'json'
        }),
        success: handleFetchStudentsSuccess,
        error: handleFetchStudentsError
      });
    }
  }

  function handleFetchStudentsSuccess(data) {
    let students = _.map(data.students, function(student) {
      return { id: student.id, name: student.name, text: student.text };
    });

    students.unshift({ id: '', name: '', text: '' });
    $student.select2({ data: students });
  }

  function handleFetchStudentsError() {
    flashMessages.error('Ocorreu um erro ao buscar os alunos.');
  }

  function resetTeacher() {
    $teacher.val('').select2({
      data: [],
      formatNoMatches: function() { return TEACHER_PLACEHOLDER; }
    });
  }

  function resetStudent() {
    $student.val('').select2({
      data: [],
      formatNoMatches: function() { return STUDENT_PLACEHOLDER; }
    });
  }

  function clearFields() {
    $classroom.val('').select2({ data: [] });
    $discipline.val('').select2({ data: [] });
    resetTeacher();
    resetStudent();
  }

  $('form').submit(function () {
    var tempoEspera = 2000;

    // Define um timeout para habilitar o botão após o tempo de espera
    setTimeout(function () {
      $('#btn-submit').prop('disabled', false);
    }, tempoEspera);
  });
});
