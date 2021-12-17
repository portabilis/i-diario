$(function () {
  'use strict';
  const flashMessages = new FlashMessages();
  let errors = {};

  $('input.table_lessons_td_select').on('change', function () {
    let teacher_discipline_classroom_id = $(this).val();
    let lesson_number = $(this).closest('tr').find('[data-id="lesson_number"]').val();
    let weekday = $(this).closest('td').find('[data-id="weekday"]').val();
    let classroom_id = $('#lessons_board_classroom_id').select2('val');

    checkExistsTeacherOnLessonNumberAndWeekday(teacher_discipline_classroom_id, lesson_number, weekday, classroom_id);
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

  function checkExistsTeacherOnLessonNumberAndWeekday(teacher_discipline_classroom_id, lesson_number, weekday, classroom_id) {
    if (_.isEmpty(teacher_discipline_classroom_id) || teacher_discipline_classroom_id === 'empty' || _.isEmpty(lesson_number) || _.isEmpty(weekday) || _.isEmpty(classroom_id)) {
      return;
    }
    $.ajax({
      url: Routes.teacher_in_other_classroom_lessons_boards_pt_br_path({
        teacher_discipline_classroom_id: teacher_discipline_classroom_id,
        lesson_number: lesson_number,
        weekday: weekday,
        classroom_id: classroom_id,
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
});
