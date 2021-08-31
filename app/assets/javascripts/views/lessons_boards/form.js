$(function () {
  'use strict';
  const flashMessages = new FlashMessages();
  const period_div = $('#period');

  $('#lessons_board_unity').on('change', function () {
    clearFields();
    clearClassroomsAndGrades();
    updateGrades();
  })

  $('#lessons_board_grade').on('change', function () {
    clearFields();
    updateClassrooms();
  })

  $('#lessons_board_classroom_id').on('change', function () {
    getPeriods();
    getNumberOfClasses();
    getTeachersFromTheClassroom()
  })

  function getTeachersFromTheClassroom() {
    let classroom_id = $('#lessons_board_classroom_id').select2('val');
    if (!_.isEmpty(classroom_id)) {
      $.ajax({
        url: Routes.teachers_classroom_lessons_boards_pt_br_path({
          classroom_id: classroom_id,
          format: 'json'
        }),
        success: handleFetchTeachersFromTheClassroomSuccess,
        error: handleFetchTeachersFromTheClassroomError
      });
    }
  }

  function handleFetchTeachersFromTheClassroomSuccess(data) {
    let teachers_to_select = _.map(data.lessons_boards, function(lessons_board) {
      return { id: lessons_board.table.id, name: lessons_board.table.name, text: lessons_board.table.text };
    });
    $("input[id*='_teacher_discipline_classroom_id']").each(function (index, teachers) {
      $(teachers).select2({ data: teachers_to_select })
    })
  }

  function handleFetchTeachersFromTheClassroomError() {
    flashMessages.error('Ocorreu um erro ao buscar os professores da turma');
  }

  function updateClassrooms() {
    let grade_id = $('#lessons_board_grade').select2('val');
    if (!_.isEmpty(grade_id)) {
      $.ajax({
        url: Routes.classrooms_filter_lessons_boards_pt_br_path({
          unity_id: grade_id,
          format: 'json'
        }),
        success: handleFetchClassroomsSuccess,
        error: handleFetchClassroomsError
      });
    }
  }

  function handleFetchClassroomsSuccess(data) {
    let classrooms = _.map(data.lessons_boards, function(lessons_board) {
      return { id: lessons_board.table.id, name: lessons_board.table.name, text: lessons_board.table.text };
    });
    $('#lessons_board_classroom_id').select2({ data: classrooms })
  }

  function handleFetchClassroomsError() {
    flashMessages.error('Ocorreu um erro ao buscar as turmas');
  }

  function updateGrades() {
    let unity_id = $('#lessons_board_unity').select2('val');
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
  }

  function handleFetchGradesSuccess(data) {
    let grades = _.map(data.lessons_boards, function(lessons_board) {
      return { id: lessons_board.table.id, name: lessons_board.table.name, text: lessons_board.table.text };
    });
    $('#lessons_board_grade').select2({ data: grades })

    updateClassrooms()
  }

  function handleFetchGradesError() {
    flashMessages.error('Ocorreu um erro ao buscar as séries a partir da escola.');
  }

  function getPeriods() {
    let classroom_id = $('#lessons_board_classroom_id').select2('val');
    if (!_.isEmpty(classroom_id)) {
      $.ajax({
        url: Routes.period_lessons_boards_pt_br_path({
          classroom_id: classroom_id,
          format: 'json'
        }),
        success: handleFetchPeriodByClassroomSuccess,
        error: handleFetchPeriodByClassroomError
      });
    } else {
      period_div.hide();
    }
  }

  function handleFetchPeriodByClassroomSuccess(data) {
    let period = $('#lessons_board_period');
    if (data === 4) {
      period.attr('readonly', false)
    } else {
      period.val(data).trigger("change")
      period.attr('readonly', true)
    }
    period_div.show();
  };

  function handleFetchPeriodByClassroomError() {
    flashMessages.error('Ocorreu um erro ao buscar os períodos da turma.');
  };

  function getNumberOfClasses() {
    let classroom_id = $('#lessons_board_classroom_id').select2('val');
    $.ajax({
      url: Routes.number_of_classes_lessons_boards_pt_br_path({
        classroom_id: classroom_id,
        format: 'json'
      }),
      success: handleFetchNumberOfClassesByClassroomSuccess,
      error: handleFetchNumberOfClassesByClassroomError
    });
  }


  function handleFetchNumberOfClassesByClassroomSuccess(data) {
    flashMessages.pop('');

    if ($("#lessons-board-lessons > tr").length > 1) {
      $("#lessons-board-lessons").empty();
    }

    for (let i = 1; i <= data; i++) {
      $('#add_row').trigger('click')
    }
    $("input[id*='_lesson_number']").each(function (index, lesson_number) {
      $(lesson_number).val(index + 1)
    })
  }

  function handleFetchNumberOfClassesByClassroomError() {
    flashMessages.error('Ocorreu um erro ao buscar os numeros de aula da turma.');
  }

  function clearClassroomsAndGrades() {
    $('#lessons_board_classroom_id').select2('val', '');
    $('#lessons_board_grade').select2('val', '');
  }

  function clearFields() {
    $("#lessons-board-lessons").empty();
    $('#period').hide();
  }
});
