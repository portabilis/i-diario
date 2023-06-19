$(document).ready(function () {
  var $classroom = $('#daily_note_classroom_id'),
    $discipline = $('#daily_note_discipline_id'),
    $unity_id = $('#daily_note_unity_id').val();

  var fetchClassrooms = function (params, callback) {
    if (!window.classrooms || window.classrooms.length === 0) {
      $.getJSON(Routes.classrooms_daily_notes_pt_br_path(), params, function (data) {
        window.classrooms = data;
        callback(window.classrooms);
      });
    } else {
      callback(window.classrooms);
    }
  };

  var fetchDisciplines = function (params, callback) {
    if (!window.disciplines || window.disciplines.length === 0) {
      $.getJSON(Routes.disciplines_daily_notes_pt_br_path(params), function (data) {
        window.disciplines = data;
        callback(window.disciplines);
      });
    } else {
      callback(window.disciplines);
    }
  };

  if ($unity_id) {
    let unity_params = { filter: { by_unity: $unity_id }, find_by_current_teacher: true };
    fetchClassrooms(unity_params, function (data) {
      let classrooms = data['daily_notes'];
      var selectedClassrooms = classrooms.map(function (classroom) {
        return { id: classroom['id'], text: classroom['description'] };
      });

      $classroom.val(selectedClassrooms[0].id).trigger('change');
    });
  }

  $classroom.on('change', function () {
    if ($classroom.val()) {
      let classroom_params = { classroom_id: $classroom.val() };

      fetchDisciplines(classroom_params, function (data) {
        let disciplines = data['daily_notes'];

        var selectedDisciplines = disciplines.map(function (discipline) {
          return { id: discipline['id'], text: discipline['description'] };
        });

        $discipline.select2({ data: selectedDisciplines }).val(selectedDisciplines[0].id).trigger('change');
      });
    }
  });
});
