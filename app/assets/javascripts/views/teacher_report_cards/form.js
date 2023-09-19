$(function () {
  'use strict';

  var flashMessages = new FlashMessages(),
    $classroom = $('#teacher_report_card_form_classroom_id'),
    $discipline = $('#teacher_report_card_form_discipline_id'),
    $unity = $("#teacher_report_card_form_unity_id"),
    $grade = $('#teacher_report_card_form_grade_id');

  $unity.on('change', function () {
    clearFields();
    getGradesbyUnity();
  });

  function getGradesbyUnity() {
    let unity_id = $unity.select2('val');

    if (!_.isEmpty(unity_id)) {
      $.ajax({
        url: Routes.grades_by_unity_lessons_boards_pt_br_path({
          unity_id: unity_id,
          format: 'json'
        }),
        success: handleFetchGradesSuccess,
        error: handleFetchGradesError
      });
    }
  };

  function handleFetchGradesSuccess(data) {
    if (data.lessons_boards.length == 0) {
      flashMessages.error('Não há séries para a turma selecionada.')
      return;
    }

    let selectedGrade = _.map(data.lessons_boards, function (grade) {
      return { id: grade.table.id, name: grade.table.name, text: grade.table.text };
    });

    // Define a primeira opção como selecionada por padrão e remove option vazia
    $grade.select2({ data: selectedGrade, allowClear: false }).find('option:eq(1)').val();
    $grade.val(selectedGrade[0].id).trigger('change');
  };

  function handleFetchGradesError() {
    flashMessages.error('Ocorreu um erro ao buscar as disciplinas da turma selecionada.');
  };

  $grade.on('change', function () {
    getClassrooms();
  });

  function getClassrooms() {
    let unity_id = $unity.select2('val');
    let grade_id = $grade.select2('val');

    if (!_.isEmpty(grade_id) || !_.isEmpty(unity_id)) {
      $.ajax({
        url: Routes.classrooms_filter_teacher_report_cards_pt_br_path({
          unity_id: unity_id,
          grade_id: grade_id,
          format: 'json'
        }),
        success: handleFetchClassroomsSuccess,
        error: handleFetchClassroomsError
      });
    }
  }

  function handleFetchClassroomsSuccess(data) {
    if (data.teacher_report_cards.length == 0) {
      flashMessages.error('Não há turmas para a unidade selecionada.')
      return;
    }

    let classrooms = _.map(data.teacher_report_cards, function (classroom) {
      return { id: classroom.table.id, name: classroom.table.name, text: classroom.table.text };
    });

    $classroom.select2({ data: classrooms, allowClear: false })
    // Define a primeira opção como selecionada por padrão
    $classroom.val(classrooms[0].id).trigger('change');
  }

  function handleFetchClassroomsError() {
    flashMessages.error('Ocorreu um erro ao buscar as turmas da escola selecionada.');
  }

  $classroom.on('change', function () {
    var classroom_id = $classroom.select2('val');

    if (!_.isEmpty(classroom_id)) {
      fetchDisciplines(classroom_id);
    } else {
      $discipline.val('').trigger('change');
      $grade.select2({ data: [] });
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

  function clearFields() {
    $classroom.val('').select2({ data: [] });
    $discipline.val('').select2({ data: [] });
  }
});
