$(document).ready(function () {
  var $classroom = $('#daily_note_classroom_id'),
    $discipline = $('#daily_note_discipline_id'),
    $unity_id = $('#daily_note_unity_id').val(),
    flashMessages = new FlashMessages();

  function fetchClassrooms (params, callback) {
    if (!window.classrooms || window.classrooms.length === 0) {
      $.getJSON(Routes.fetch_classrooms_daily_notes_pt_br_path(), params, function (data) {
        window.classrooms = data;
        callback(window.classrooms);
      });
    } else {
      callback(window.classrooms);
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
      fetchDisciplines(selectedClassrooms[0].id);
    });
  }

  $classroom.on('change', function (e) {
    if (!_.isEmpty(e.val)) {
      fetchDisciplines(e.val);
    }
  });

  function fetchDisciplines(classroom_id) {
    $.ajax({
      url: Routes.by_classroom_disciplines_pt_br_path({ classroom_id: classroom_id, format: 'json' }),
      success: handleFetchDisciplinesSuccess,
      error: handleFetchDisciplinesError
    });
  };

  function handleFetchDisciplinesSuccess(data) {
    if (data.disciplines.length == 0) {
      flashMessages.error('Não existem disciplinas para a turma selecionada.');
      return;
    }

    var selectedDisciplines = data.disciplines.map(function (discipline) {
      return { id: discipline.table.id, name: discipline.table.name, text: discipline.table.text };
    });

    $discipline.select2({ data: selectedDisciplines });
    // Define a primeira opção como selecionada por padrão
    $discipline.val(selectedDisciplines[0].id).trigger('change');
  };

  function handleFetchDisciplinesError() {
    flashMessages.error('Ocorreu um erro ao buscar as disciplinas da turma selecionada.');
  };
});
