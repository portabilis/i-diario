$(function () {
  'use strict';

  var flashMessages = new FlashMessages();
  var $classroom = $('#teacher_report_card_form_classroom_id');
  var $discipline = $('#teacher_report_card_form_discipline_id');
  var $grade = $('#teacher_report_card_form_grade_id');

  $classroom.on('change', async function () {
    var classroom_id = $classroom.select2('val');

    $discipline.select2('val', '');
    $discipline.select2({ data: [] });

    if (!_.isEmpty(classroom_id)) {
      fetchDisciplines(classroom_id);
      getGrades(classroom_id);
    } else {
      $discipline.val('').trigger('change');
      $grade.select2({ data: [] });
    }
  });

  function fetchDisciplines(classroom_id) {
    $.ajax({
      url: Routes.disciplines_pt_br_path({ classroom_id: classroom_id, format: 'json' }),
      success: handleFetchDisciplinesSuccess,
      error: handleFetchDisciplinesError
    });
  };

  function handleFetchDisciplinesSuccess(disciplines) {
    var selectedDisciplines = _.map(disciplines, function (discipline) {
      return { id: discipline['id'], text: discipline['description'] };
    });

    $discipline.select2({ data: selectedDisciplines });

    // Define a primeira opção como selecionada por padrão
    $discipline.val(selectedDisciplines[0].id).trigger('change');
  };

  function handleFetchDisciplinesError() {
    flashMessages.error('Ocorreu um erro ao buscar as disciplinas da turma selecionada.');
  };

  async function getGrades() {
    let classroom_id = $classroom.select2('val');

    if (!_.isEmpty(classroom_id)) {
      return $.ajax({
        url: Routes.grade_teacher_report_cards_pt_br_path({
          classroom_id: classroom_id,
          format: 'json'
        }),
        success: handleFetchGradesByClassroomSuccess,
        error: handleFetchGradesByClassroomError
      });
    }
  }


  function handleFetchGradesByClassroomSuccess(data) {
    let grades = data['teacher_report_cards'];

    var selectedGrade = _.map(grades, function (grade) {
      return { id: grade['id'], text: grade['description'] };
    });

    $grade.select2({ data: selectedGrade });

    // Define a primeira opção como selecionada por padrão
    $grade.val(selectedGrade[0].id).trigger('change');
  };

  function handleFetchGradesByClassroomError() {
    flashMessages.error('Ocorreu um erro ao buscar as disciplinas da turma selecionada.');
  };

});
