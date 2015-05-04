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

  $('#avaliation_unity_id').on('change', function (e) {
    var $classroom = $('#avaliation_classroom_id'),
        params = {
          unity_id: e.val
        };

    window.classrooms = [];

    if (_.isEmpty(e.val)) {
      $classroom.val('');
      $classroom.select2({
        data: []
      });

    } else {
      fetchClassrooms(params, function (classrooms) {
        var selectedClassrooms = _.map(classrooms, function (classroom) {
          return { id:classroom['id'], text: classroom['description'] };
        });

        $classroom.select2({
          data: selectedClassrooms
        });
      });
    }
  });

  $('#avaliation_classroom_id').on('change', function (e) {
    var $discipline = $('#avaliation_discipline_id'),
        params = {
          classroom_id: e.val
        };
    window.disciplines = [];

    if (_.isEmpty(e.val)) {
      $discipline.val('');
      $discipline.select2({
        data: []
      });

    } else {
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
