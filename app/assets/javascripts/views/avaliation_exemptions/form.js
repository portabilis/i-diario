$(function () {
  'use strict';

  var flashMessages = new FlashMessages();
  var $unity = $('#avaliation_exemption_unity_id');
  var $course = $('#avaliation_exemption_course_id');
  var $grade = $('#avaliation_exemption_grade_id');
  var $classroom = $('#avaliation_exemption_classroom_id');
  var $year = $('#avaliation_exemption_school_calendar_year');
  var $discipline = $('#avaliation_exemption_discipline_id');
  var $school_calendar_step = $('#avaliation_exemption_school_calendar_step');
  var $avaliation = $('#avaliation_exemption_avaliation_id');
  var $student = $('#avaliation_exemption_student_id');
  var $school_calendar_step_start_at = $('#avaliation_exemption_school_calendar_step_start_at');
  var $school_calendar_step_end_at = $('#avaliation_exemption_school_calendar_step_end_at');
  var $avaliation_date = $('#avaliation_exemption_avaliation_date');

  fetchCourses();

  $course.on('change', function(){
    fetchGrades();
  });

  $grade.on('change', function(){
    fetchClassrooms();
  });

  $classroom.on('change', function(){
    fetchDisciplines();
    fetchAvaliations();
  });

  $discipline.on('change', function(){
    fetchAvaliations();
  });

  $school_calendar_step.on('change', function(){
    fetchAvaliations();
  });

  $avaliation.on('change', function(){
    fetchAvaliationDate();
  });

  function fetchCourses() {
    var unity_id = $unity.select2('val');
    var filter = { by_unity: unity_id };
    if (!_.isEmpty(unity_id)) {
      $.ajax({
        url: Routes.courses_pt_br_path({
            filter: filter,
            format: 'json'
        }),
        success: handleFetchCoursesSuccess,
        error: handleFetchCoursesError
      });
    }
  };

  function handleFetchCoursesSuccess(courses) {
    var selectedCourses = _.map(courses, function(course) {
      return { id: course['id'], text: course['description'] };
    });

    $course.select2({ data: selectedCourses });
  };

  function handleFetchCoursesError() {
    flashMessages.error('Ocorreu um erro ao buscar os cursos da escola selecionada.');
  };

  function fetchGrades() {
    var unity_id = $unity.select2('val');
    var course_id = $course.select2('val');
    var filter = {
      by_unity: unity_id,
      by_course: course_id
    };

    if (!_.isEmpty(unity_id) && !_.isEmpty(course_id)) {
      $.ajax({
        url: Routes.grades_pt_br_path({
          filter: filter,
          format: 'json'
        }),
        success: handleFetchGradesSuccess,
        error: handleFetchGradesError
      });
    }
  };

  function handleFetchGradesSuccess(grades) {
    var selectedGrades = _.map(grades, function(grade) {
      return { id: grade['id'], text: grade['description'] };
    });

    $grade.select2({ data: selectedGrades });
  };

  function handleFetchGradesError() {
    flashMessages.error('Ocorreu um erro ao buscar as séries da escola selecionada.');
  };

  function fetchClassrooms() {
    var unity_id = $unity.select2('val');
    var grade_id = $grade.select2('val');
    var year     = $year.val();

    if (!_.isEmpty(unity_id) && !_.isEmpty(grade_id)) {
      var filter = {
        by_unity: unity_id,
        by_grade: grade_id,
        by_year: year
      };
      $.ajax({
        url: Routes.classrooms_pt_br_path({
          filter: filter,
          format: 'json'
        }),
        success: handleFetchClasroomsSuccess,
        error: handleFetchGradesError
      });
    }
  };

  function handleFetchClasroomsSuccess(classrooms) {
    var selectedClassrooms = _.map(classrooms, function(classroom) {
      return { id: classroom['id'], text: classroom['description'] };
    });

    $classroom.select2({ data: selectedClassrooms });
  };

  function handleFetchClassroomsError() {
    flashMessages.error('Ocorreu um erro ao buscar as turmas da série selecionada.');
  };

  function fetchDisciplines() {
    var classroom_id = $classroom.select2('val');

    if (!_.isEmpty(classroom_id)) {
      var filter = {
        by_classroom: classroom_id
      };
      $.ajax({
        url: '/disciplinas/search',
        data: filter,
        success: handleFetchDisciplinesSuccess,
        error: handleFetchDisciplinesError
      });
    }
  };

  function handleFetchDisciplinesSuccess(disciplines) {
    var selectedDisciplines = _.map(disciplines['disciplines'], function(discipline) {
      return { id: discipline['id'], text: discipline['description'] };
    });

    $discipline.select2({ data: selectedDisciplines });
  };

  function handleFetchDisciplinesError() {
    flashMessages.error('Ocorreu um erro ao buscar as disciplinas da turma selecionada.');
  };

  function fetchAvaliations() {
    var classroom_id = $classroom.select2('val');
    var discipline_id = $discipline.select2('val');
    var school_calendar_step_id = $school_calendar_step.select2('val');

    if (!_.isEmpty(classroom_id) && !_.isEmpty(discipline_id) && !_.isEmpty(school_calendar_step_id)) {
      var filter = {
        by_classroom_id: classroom_id,
        by_discipline_id: discipline_id,
        by_school_calendar_step: school_calendar_step_id
      };
      $.ajax({
        url: '/avaliations/search',
        data: filter,
        success: handleFetchAvaliationsSuccess,
        error: handleFetchAvaliationsError
      });
    }
  };

  function handleFetchAvaliationsSuccess(avaliations) {
    var selectedAvaliations = _.map(avaliations['avaliations'], function(avaliation) {
      return { id: avaliation['id'], text: avaliation['description'] };
    });

    $avaliation.select2({ data: selectedAvaliations });
  };

  function handleFetchAvaliationsError() {
    flashMessages.error('Ocorreu um erro ao buscar as avaliações da turma e disciplina selecionadas.');
  };

  function fetchAvaliationDate() {
    var avaliation_id = $avaliation.select2('val');

    if (!_.isEmpty(avaliation_id)) {

      $.ajax({
        url: '/avaliations/' + avaliation_id,
        success: handleFetchAvaliationDateSuccess,
        error: handleFetchAvaliationDateError
      });
    }
  };

  function handleFetchAvaliationDateSuccess(avaliation) {
    $avaliation_date.val(avaliation['avaliation'].test_date)
    fetchStudents();
  };

  function handleFetchAvaliationDateError() {
    flashMessages.error('Ocorreu um erro ao buscar a data da avaliação selecionada.');
  };

  function fetchStudents() {
    var classroom_id = $classroom.select2('val');
    var avaliation_date = $('#avaliation_exemption_avaliation_date').val();

    if (!_.isEmpty(classroom_id) && !_.isEmpty(avaliation_date)) {
      $.ajax({
        url: Routes.classroom_students_pt_br_path({ classroom_id: classroom_id, date: avaliation_date, format: 'json' }),
        success: handleFetchStudentsSuccess,
        error: handleFetchStudentsError
      });
    }
  };

  function handleFetchStudentsSuccess(students) {
    var selectedStudents = _.map(students['students'], function(student) {
      return { id: student['id'], text: student['name'] };
    });

    $student.select2({ data: selectedStudents });
  };

  function handleFetchStudentsError() {
    flashMessages.error('Ocorreu um erro ao buscar os alunos da avaliação selecionada.');
  };

});
