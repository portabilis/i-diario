$(function () {
  'use strict';

  let flashMessages = new FlashMessages();
  let $unity = $('#observation_record_report_form_unity_id');
  let $classroom = $('#observation_record_report_form_classroom_id');
  let $discipline = $('#observation_record_report_form_discipline_id');

  $(document).ready(function() {
    $('#btn-submit').attr("disabled", true);
    getClassrooms();
    getDisciplines();
  });

  $unity.on('change', function () {
    clearFields();
    getClassrooms();
    getDisciplines();
  });

  $classroom.on('change', function() {
    $discipline.val('').select2({ data: [] });
    emptyDiscipline();
    getDisciplines();
  });

  $discipline.on('change', function() {
    emptyDiscipline();
  })

  function emptyDiscipline() {
    if ($discipline.val() !== '') {
      $('#btn-submit').attr("disabled", false);
    } else {
      $('#btn-submit').attr("disabled", true);
    }
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

    if (!_.isEmpty(classroom_id)) {
      $.ajax({
        url: Routes.by_classroom_disciplines_pt_br_path({ classroom_id: classroom_id, format: 'json' }),
        success: handleFetchDisciplinesSuccess,
        error: handleFetchDisciplinesError
      });
    }
  }

  function handleFetchDisciplinesSuccess(data) {
    let selectedDisciplines = _.map(data.disciplines, function(discipline) {
      return { id: discipline.table.id, name: discipline.table.name, text: discipline.table.text };
    });

    if (selectedDisciplines.length > 1) {
      selectedDisciplines.unshift({ id: 'all', name: '<option>Todas</option>', text: 'Todas' });
    }

    $discipline.select2({ data: selectedDisciplines });
  }

  function handleFetchDisciplinesError() {
    flashMessages.error('Ocorreu um erro ao buscar as disciplinas da turma selecionada.');
  }

  function clearFields() {
    $classroom.val('').select2({ data: [] });
    $discipline.val('').select2({ data: [] });
  }

  $('form').submit(function () {
    var tempoEspera = 2000;

    // Define um timeout para habilitar o botão após o tempo de espera
    setTimeout(function () {
      $('#btn-submit').prop('disabled', false);
    }, tempoEspera);
  });
});
