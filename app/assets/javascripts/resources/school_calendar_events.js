$(function () {
  window.grades = [];
  window.classrooms = [];

  var $schoolCalendar = $('#school_calendar_event_school_calendar_id');
  var $course = $('#school_calendar_event_course_id');
  var $grade = $('#school_calendar_event_grade_id');
  var $classroom = $('#school_calendar_event_classroom_id');

  var fetchGrades = function (params, callback) {
    if (_.isEmpty(window.grades)) {
      $.getJSON('/calendarios-letivo/'+$schoolCalendar.val()+'/eventos/grades?' + $.param(params)).always(function (data) {
        window.grades = data.grades;
        callback(window.grades);
      });
    } else {
      callback(window.grades);
    }
  };

  var fetchClassrooms = function (params, callback) {
    if (_.isEmpty(window.classrooms)) {
      $.getJSON('/calendarios-letivo/'+$schoolCalendar.val()+'/eventos/turmas?' + $.param(params)).always(function (data) {
        window.classrooms = data.classrooms;
        callback(window.classrooms);
      });
    } else {
      callback(window.classrooms);
    }
  };

  $course.on('change', function (e) {
    var params = {
      course_id: e.val
    };

    window.grades = [];
    window.classrooms = [];

    $grade.val('').select2({ data: [] });
    $classroom.val('').select2({ data: [] });

    if (!_.isEmpty(e.val)) {
      fetchGrades(params, function (grades) {
        var selectedGrades = _.map(grades, function (grade) {
          return { id:grade['id'], text: grade['description'] };
        });

        $grade.select2({
          data: selectedGrades
        });
      });
    }
  });

  $grade.on('change', function (e) {
    var params = {
      grade_id: e.val
    };

    window.classrooms = [];

    $classroom.val('').select2({ data: [] });

    if (!_.isEmpty(e.val)) {
      fetchClassrooms(params, function (classrooms) {
        console.log(classrooms);
        var selectedClassrooms = _.map(classrooms, function (classroom) {
          return { id:classroom['id'], text: classroom['description'] };
        });
        console.log(selectedClassrooms);

        $classroom.select2({
          data: selectedClassrooms
        });
      });
    }
  });
});
