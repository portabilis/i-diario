$(function () {
  var $classroom = $('#daily_note_classroom_id'),
    $discipline = $('#daily_note_discipline_id'),
    flashMessages = new FlashMessages();

  $classroom.on('change', function (e) {
    if (!_.isEmpty(e.val)) {
      fetchDisciplines(e.val);
    }
  });

  function fetchDisciplines(classroom_id) {
    $.ajax({
      url: Routes.by_classroom_disciplines_pt_br_path({
        classroom_id: classroom_id,
        format: 'json'
      }),
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
