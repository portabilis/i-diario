$(function () {
  window.classrooms = [];
  window.disciplines = [];

  var fetchClassrooms = function (params, callback) {
    if (_.isEmpty(window.classrooms)) {
      $.getJSON('/classrooms?' + $.param(params)).always(function (data) {
        window.classrooms = data;
        callback(window.classrooms);
      });
    } else {
      callback(window.classrooms);
    }
  };

  var fetchDisciplines = function (params, callback) {
    if (_.isEmpty(window.disciplines)) {
      $.getJSON('/disciplines?' + $.param(params)).always(function (data) {
        window.disciplines = data;
        callback(window.disciplines);
      });
    } else {
      callback(window.disciplines);
    }
  };

  $('#teaching_plan_unity_id').on('change', function (e) {
    var $classroom = $('#teaching_plan_classroom_id');
    var params = { unity_id: e.val };

    window.classrooms = [];

    $classroom.val('');
    $classroom.select2({ data: [] });

    if (!_.isEmpty(e.val)) {
      fetchClassrooms(params, function(classrooms) {
        var selectedClassrooms = _.map(classrooms, function (classroom) {
          return { id:classroom['id'], text: classroom['description'] };
        });

        $classroom.select2({
          data: selectedClassrooms
        });
      });
    }
  });

  $('#teaching_plan_classroom_id').on('change', function (e) {
    var $discipline = $('#teaching_plan_discipline_id');
    var params = { classroom_id: e.val };

    window.disciplines = [];

    $discipline.val('');
    $discipline.select2({ data: [] });

    if (!_.isEmpty(e.val)) {
      fetchDisciplines(params, function (disciplines) {
        var selectedDisciplines = _.map(disciplines, function (discipline) {
          return { id:discipline['id'], text: discipline['description'] };
        });

        $discipline.select2({
          data: selectedDisciplines
        });
      });
    }
  });
});
