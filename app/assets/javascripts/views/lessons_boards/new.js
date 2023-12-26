$(function () {
  'use strict';
  const flashMessages = new FlashMessages();
  const period_div = $('#period');
  const PERIOD_FULL = 4;
  let errors = {};

  $(document).ready( function() {
    clearFields();
    clearClassroomsAndGrades();
    if ($('#lessons_board_unity').val()) {
      updateGrades();
    }
    $('#btn-submit').attr("disabled", true);
  });

  $('#lessons_board_unity').on('change', async function () {
    errors = {};
    flashMessages.pop('');
    clearFields();
    clearClassroomsAndGrades();
    period_div.hide();
    $('#btn-submit').attr("disabled", true);
    await updateGrades();
  })

  $('#lessons_board_grade').on('change', async function () {
    errors = {};
    flashMessages.pop('');
    clearFields();
    $('#lessons_board_classroom_id').select2('val', '');
    period_div.hide();
    $('#btn-submit').attr("disabled", true);
    await updateClassrooms();
  })

  $('#lessons_board_classroom_id').on('change', async function () {
    errors = {};
    flashMessages.pop('');
    $('#lessons_board_period').select2('val', '');
    await getPeriod();
    let period = $('#lessons_number_classroom_id').val();

    if (period != PERIOD_FULL) {
      checkMultiGrade();
    }

    period_div.show();

    populateClassroomGradeId();
  })

  function populateClassroomGradeId() {
    let grade_id = $('#lessons_board_grade').select2('val');
    let classroom_id = $('#lessons_board_classroom_id').select2('val');

    $.ajax({
      url: Routes.classroom_grade_lessons_boards_pt_br_path({
        grade_id: grade_id,
        classroom_id: classroom_id,
      }),
      success: function(data) {
        $('#lessons_board_classrooms_grade_id').val(data)
      },
      error: function() {
        flashMessages.error('Ocorreu um erro ao buscar a série vinculada a turma.');
      }
    });
  }

  $('#lessons_board_period').on('change', function() {
    errors = {};
    let period = $('#lessons_number_classroom_id').val();

    if (period == PERIOD_FULL) {
      checkNotExistsLessonsBoardOnPeriod();
    }
  })

  $('#btn-submit').on('click', function (e) {
    e.preventDefault();
    clearEmptyTeachers();
    for (let prop in errors) {
      if (errors[prop]) {
        flashMessages.error(errors[prop]);
        return
      }
    }
    $('#form-submit').submit();
  })

  function checkExistsTeacherOnLessonNumberAndWeekday(teacher_discipline_classroom_id, lesson_number, weekday, classroom_id, lessons_board_period) {
    if (
      _.isEmpty(teacher_discipline_classroom_id) || teacher_discipline_classroom_id === 'empty'
      || _.isEmpty(lesson_number) || _.isEmpty(weekday) || _.isEmpty(classroom_id) || _.isEmpty(lessons_board_period)
    ) {
      return;
    }
    $.ajax({
      url: Routes.teacher_in_other_classroom_lessons_boards_pt_br_path({
        teacher_discipline_classroom_id: teacher_discipline_classroom_id,
        lesson_number: lesson_number,
        weekday: weekday,
        classroom_id: classroom_id,
        period: lessons_board_period,
        format: 'json'
      }),
      success: function(data) {
        if (data != false) {
          errors[weekday + '-' + lesson_number] = data.table.message
          flashMessages.error(data.table.message);
        } else {
          errors[weekday + '-' + lesson_number] = null
          flashMessages.pop('');
        }
      },
      error: function() {
        flashMessages.error('Ocorreu um erro ao buscar os vínculos do professor.');
      }
    });
  }

  function clearEmptyTeachers() {
    $("input[id*='_teacher_discipline_classroom_id']").each(function (index, teacher_discipline_classroom_id) {
      if ($(teacher_discipline_classroom_id).val() == 'empty') {
        $(teacher_discipline_classroom_id).val('')
      }
    })
  }


  async function updateGrades() {
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
  }

  function handleFetchGradesError() {
    flashMessages.error('Ocorreu um erro ao buscar as séries.');
  }

  async function updateClassrooms() {
    let unity_id = $('#lessons_board_unity').select2('val');
    let grade_id = $('#lessons_board_grade').select2('val');
    if (!_.isEmpty(grade_id) || !_.isEmpty(unity_id)) {
      $.ajax({
        url: Routes.classrooms_filter_lessons_boards_pt_br_path({
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
    let classrooms = _.map(data.lessons_boards, function(lessons_board) {
      return { id: lessons_board.table.id, name: lessons_board.table.name, text: lessons_board.table.text };
    });
    $('#lessons_board_classroom_id').select2({ data: classrooms })
  }

  function handleFetchClassroomsError() {
    flashMessages.error('Ocorreu um erro ao buscar as turmas.');
  }

  async function getPeriod() {
    let classroom_id = $('#lessons_board_classroom_id').select2('val');

    if (!_.isEmpty(classroom_id)) {
      return $.ajax({
        url: Routes.period_lessons_boards_pt_br_path({
          classroom_id: classroom_id,
          format: 'json'
        }),
        success: handleFetchPeriodByClassroomSuccess,
        error: handleFetchPeriodByClassroomError
      });
    }
  }

  function handleFetchPeriodByClassroomSuccess(data) {
    $('#lessons_number_classroom_id').val(data);
    let period = $('#lessons_board_period');

    if (data != PERIOD_FULL) {
      getNumberOfClasses();
      period.val(data).trigger("change")
      period.attr('readonly', true)
    } else {
      period.attr('readonly', false)
    }
  };

  function handleFetchPeriodByClassroomError() {
    flashMessages.error('Ocorreu um erro ao buscar o período da turma.');
  };

  function checkMultiGrade() {
    let classroom_id = $('#lessons_board_classroom_id').select2('val');

    if (!_.isEmpty(classroom_id)) {
      $.ajax({
        url: Routes.classroom_multi_grade_lessons_boards_pt_br_path({
          classroom_id: classroom_id,
          format: 'json'
        }),
        success: handleMultiGradeSuccess,
        error: handleMultiGradeError
      });
    }
  }

  function handleMultiGradeSuccess(data) {
    if (data) {
      checkNotExistsLessonsBoardByClassroomGrade();
    } else {
      checkNotExistsLessonsBoard()
    }
  }

  function handleMultiGradeError() {
    flashMessages.error('Ocorreu um erro ao buscar a turma.');
  };


  function checkNotExistsLessonsBoardByClassroomGrade() {
    let classroom_id = $('#lessons_board_classroom_id').select2('val');
    let grade_id = $('#lessons_board_grade').select2('val');

    if (!_.isEmpty(classroom_id) && !_.isEmpty(grade_id)) {
      $.ajax({
        url: Routes.not_exists_by_classroom_and_grade_lessons_boards_pt_br_path({
          classroom_id: classroom_id,
          grade_id: grade_id,
          format: 'json'
        }),
        success: handleNotExistsLessonsBoardSuccess,
        error: handleNotExistsLessonsBoardError
      });
    }
  }

  function checkNotExistsLessonsBoard() {
    let classroom_id = $('#lessons_board_classroom_id').select2('val');

    if (!_.isEmpty(classroom_id)) {
      $.ajax({
        url: Routes.not_exists_by_classroom_lessons_boards_pt_br_path({
          classroom_id: classroom_id,
          format: 'json'
        }),
        success: handleNotExistsLessonsBoardSuccess,
        error: handleNotExistsLessonsBoardError
      });
    }
  }

  function handleNotExistsLessonsBoardSuccess(data) {
    if (data) {
      getTeachersFromClassroom();
      $('#btn-submit').attr("disabled", false);
    } else {
      clearFields();
      $('#btn-submit').attr("disabled", true);
      flashMessages.error('Já existe um quadro de aula cadastrado para a turma selecionada.');
    }
  }

  function handleNotExistsLessonsBoardError() {
    flashMessages.error('Ocorreu um erro ao validar a existencia de uma calendário para essa turma.');
  }

  function checkNotExistsLessonsBoardOnPeriod() {
    let classroom_id = $('#lessons_board_classroom_id').select2('val');
    let period = $('#lessons_board_period').select2('val');

    if (!_.isEmpty(classroom_id)) {
      $.ajax({
        url: Routes.not_exists_by_classroom_and_period_lessons_boards_pt_br_path({
          classroom_id: classroom_id,
          period: period,
          format: 'json'
        }),
        success: handleNotExistsLessonsBoardOnPeriodSuccess,
        error: handleNotExistsLessonsBoardOnPeriodError
      });
    }
  }

  function handleNotExistsLessonsBoardOnPeriodSuccess(data) {
    if (data) {
      $('#btn-submit').attr("disabled", false);
      getNumberOfClasses();
      getTeachersFromClassroomAndPeriod();
    } else {
      clearFields();
      $('#btn-submit').attr("disabled", true);
      flashMessages.error('Já existe um quadro de aula cadastrado para a turma e período selecionado.');
    }
  }

  function handleNotExistsLessonsBoardOnPeriodError() {
    flashMessages.error('Ocorreu um erro ao validar a existencia de uma calendário para essa turma e período.');
  }

  async function getTeachersFromClassroom() {
    let classroom_id = $('#lessons_board_classroom_id').select2('val');
    let grade_id = $('#lessons_board_grade').select2('val');

    if (!_.isEmpty(classroom_id)) {
      return $.ajax({
        url: Routes.teachers_classroom_lessons_boards_pt_br_path({
          classroom_id: classroom_id,
          grade_id: grade_id,
          format: 'json'
        }),
        success: handleFetchTeachersFromTheClassroomSuccess,
        error: handleFetchTeachersFromTheClassroomError
      });
    }
  }

  function getTeachersFromClassroomAndPeriod() {
    let classroom_id = $('#lessons_board_classroom_id').select2('val');
    let period = $('#lessons_board_period').select2('val');
    let grade_id = $('#lessons_board_grade').select2('val');

    if (!_.isEmpty(classroom_id)) {
      $.ajax({
        url: Routes.teachers_classroom_period_lessons_boards_pt_br_path({
          classroom_id: classroom_id,
          grade_id: grade_id,
          period: period,
          format: 'json'
        }),
        success: handleFetchTeachersFromTheClassroomSuccess,
        error: handleFetchTeachersFromTheClassroomError
      });
    }
  }

  function handleFetchTeachersFromTheClassroomSuccess(data) {
    if (data.lessons_boards.length < 2) {
      clearFields();
      flashMessages.error('A turma selecionada não possui vínculo com professores(as).');
    } else {
      let teachers_to_select = _.map(data.lessons_boards, function(lessons_board) {
        return { id: lessons_board.table.id, name: lessons_board.table.name, text: lessons_board.table.text };
      });

      $("input[id*='_teacher_discipline_classroom_id']").each(function (index, teachers) {
        $(teachers).select2({ data: teachers_to_select, escapeMarkup, formatResult })
      })
    }
  }

  function escapeMarkup(data) {
    return data;
  }

  function formatResult(state) {
    return state.name;
  }

  function handleFetchTeachersFromTheClassroomError() {
    flashMessages.error('Ocorreu um erro ao buscar os professores da turma.');
  }

  function getNumberOfClasses() {
    let classroom_id = $('#lessons_board_classroom_id').select2('val');

    $.ajax({
      url: Routes.number_of_lessons_lessons_boards_pt_br_path({
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

    $('input.table_lessons_td_select').on('change', function () {
      let teacher_discipline_classroom_id = $(this).val();
      let lesson_number = $(this).closest('tr').find('[data-id="lesson_number"]').val();
      let weekday = $(this).closest('td').find('[data-id="weekday"]').val();
      let classroom_id = $('#lessons_board_classroom_id').select2('val');
      let period = $('#lessons_board_period').select2('val');

      checkExistsTeacherOnLessonNumberAndWeekday(teacher_discipline_classroom_id, lesson_number, weekday, classroom_id, period);
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
  }
});
