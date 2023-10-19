$(document).ready(function () {
  'use strict';

  let flashMessages = new FlashMessages(),
    redirect_link_report_card = Routes.teacher_report_cards_pt_br_path(),
    redirect_link_conceptual_exams = Routes.conceptual_exams_pt_br_path(),
    redirect_link_descriptive_exams = Routes.new_descriptive_exam_pt_br_path(),
    message = `O <b>Registros de avaliações numéricas</b> apresentará somente as notas lançadas nos diários de avaliação e recuperações numéricas. Para conferência de notas conceituais e/ou descritivas acessar, respectivamente, o <a href="${redirect_link_report_card}"><b>Boletim do professor</b></a> ou as telas de <a href="${redirect_link_conceptual_exams}"><b>Diário de avaliações conceituais</b></a> e <a href="${redirect_link_descriptive_exams}"><b>Avaliações descritivas</b></a>.`;

  flashMessages.info(message);

  var $classroom = $('#exam_record_report_form_classroom_id'),
    $discipline = $('#exam_record_report_form_discipline_id'),
    $step = $('#exam_record_report_form_school_calendar_step_id'),
    $unity = $('#exam_record_report_form_unity_id');

  $unity.on('change', function () {
    clearFields();
    getClassrooms();
  });

  function clearFields() {
    $classroom.val('').select2({ data: [] });
    $discipline.val('').select2({ data: [] });
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
    let classrooms = _.map(data.classrooms, function (classroom) {
      return { id: classroom.table.id, name: classroom.table.name, text: classroom.table.text };
    });

    classrooms.unshift({ id: 'all', name: '<option>Todas</option>', text: 'Todas' });

    $classroom.select2({ data: classrooms })
  }

  function handleFetchClassroomsError() {
    flashMessages.error('Ocorreu um erro ao buscar as turmas da escola selecionada.');
  }

  $classroom.on('change', async function (e) {
    let classroom_id = $classroom.select2('val');

    $discipline.val('').select2({ data: [] });

    if (!_.isEmpty(classroom_id)) {
      await getStep();
      fetchDisciplines(classroom_id);
    } else {
      $discipline.val('').trigger('change');
      $step.select2({ data: [] }).trigger('change');
    }
  });

  async function getStep() {
    let classroom_id = $classroom.select2('val');

    if (!_.isEmpty(classroom_id)) {
      return $.ajax({
        url: Routes.fetch_step_exam_record_report_pt_br_path({
          classroom_id: classroom_id,
          format: 'json'
        }),
        success: handleFetchStepByClassroomSuccess,
        error: handleFetchStepByClassroomError
      });
    }
  }

  function handleFetchStepByClassroomSuccess(data) {
    let selectedSteps = data.map(function (step) {
      return { id: step['id'], text: step['description'] };
    });

    $step.select2({ data: selectedSteps });
    // Define a primeira opção como selecionada por padrão
    $step.val(selectedSteps[0].id).trigger('change');
  };

  function handleFetchStepByClassroomError() {
    flashMessages.error('Ocorreu um erro ao buscar a etapa da turma.');
  };

  function fetchDisciplines(classroom_id) {
    $.ajax({
      url: Routes.by_classroom_disciplines_pt_br_path({ classroom_id: classroom_id, format: 'json' }),
      success: handleFetchDisciplinesSuccess,
      error: handleFetchDisciplinesError
    });
  };

  function handleFetchDisciplinesSuccess(data) {

    if (_.isEmpty(data)) {
      flashMessages.error('Não existem disciplinas para a turma selecionada.');
      return;
    } else {
      var selectedDisciplines = data.disciplines.map(function (discipline) {
        return { id: discipline.table.id, name: discipline.table.name, text: discipline.table.text };
      });

      $discipline.select2({ data: selectedDisciplines });

      // Define a primeira opção como selecionada por padrão
      $discipline.val(selectedDisciplines[0].id).trigger('change');
    }
  };

  function handleFetchDisciplinesError() {
    flashMessages.error('Ocorreu um erro ao buscar as disciplinas da turma selecionada.');
  };

  $('form').submit(function (event) {
    var tempoEspera = 2000;

    // Define um timeout para habilitar o botão após o tempo de espera
    setTimeout(function () {
      $('#send-form').prop('disabled', false);
    }, tempoEspera);
  });
});
