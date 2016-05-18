$(function () {
  'use strict';

  var flashMessages = new FlashMessages();
  var $unity = $('#avaliation_exemption_unity_id');
  var $course = $('#avaliation_exemption_course_id');
  var $grade = $('#avaliation_exemption_grade_id');

  fetchCourses();

  $course.on('change', function(){
    fetchGrades();
  });

  function fetchCourses() {
    var unity_id = $unity.select2('val');

    $course.select2('val', '');
    $course.select2({ data: [] });

    if (!_.isEmpty(unity_id)) {
      $.ajax({
        url: Routes.lectures_pt_br_path({ unity_ids: unity_id, format: 'json' }),
        success: handleFetchCoursesSuccess,
        error: handleFetchCoursesError
      });
    }
  };

  function handleFetchCoursesSuccess(courses) {
    var selectedCourses = _.map(courses, function(course) {
      return { id: course['id'], text: course['name'] };
    });

    $course.select2({ data: selectedCourses });
  };

  function handleFetchCoursesError() {
    flashMessages.error('Ocorreu um erro ao buscar os cursos da escola selecionada.');
  };

  function fetchGrades() {
    var unity_id = $unity.select2('val');
    var course_id = $course.select2('val');

    $grade.select2('val', '');
    $grade.select2({ data: [] });

    if (!_.isEmpty(unity_id) || !_.isEmpty(course_id)) {
      $.ajax({
        url: Routes.grades_pt_br_path({ escola_id: unity_id, curso_id: course_id, format: 'json' }),
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
});
