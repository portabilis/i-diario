$(function () {
  'use strict';

  // Regular expression for dd/mm/yyyy date including validation for leap year and more
  var dateRegex = '^(?:(?:31(\\/)(?:0?[13578]|1[02]))\\1|(?:(?:29|30)(\\/)(?:0?[1,3-9]|1[0-2])\\2))(?:(?:1[6-9]|[2-9]\\d)?\\d{2})$|^(?:29(\\/)0?2\\3(?:(?:(?:1[6-9]|[2-9]\\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00))))$|^(?:0?[1-9]|1\\d|2[0-8])(\\/)(?:(?:0?[1-9])|(?:1[0-2]))\\4(?:(?:1[6-9]|[2-9]\\d)?\\d{2})$';

  var flashMessages = new FlashMessages();
  var $classroom = $('#transfer_note_classroom_id');
  var $discipline = $('#transfer_note_discipline_id');
  var $step = $('#transfer_note_step_id');
  var $recordedAt = $('#transfer_note_recorded_at');
  var $student = $('#transfer_note_student_id');


  $classroom.on('change', async function () {
    var classroom_id = $classroom.select2('val');

    $discipline.val('').select2({ data: [] });

    if (!_.isEmpty(classroom_id)) {
      await getStep();
      await fetchDisciplines(classroom_id);
    } else {
      $discipline.val('').trigger('change');
      $step.select2({ data: [] });
    }
  });

  async function fetchDisciplines(classroom_id) {
    $.ajax({
      url: Routes.disciplines_pt_br_path({ classroom_id: classroom_id, format: 'json' }),
      success: handleFetchDisciplinesSuccess,
      error: handleFetchDisciplinesError
    });
  };

  function handleFetchDisciplinesSuccess(disciplines) {
    let selectedDisciplines = disciplines.map(function (discipline) {
      return { id: discipline['id'], text: discipline['description'] };
    });

    $discipline.select2({ data: selectedDisciplines });

    // Define a primeira opção como selecionada por padrão
    $discipline.val(selectedDisciplines[0].id).trigger('change');
  };

  function handleFetchDisciplinesError() {
    flashMessages.error('Ocorreu um erro ao buscar as disciplinas da turma selecionada.');
  };

  async function getStep() {
    let classroom_id = $classroom.select2('val');

    if (!_.isEmpty(classroom_id)) {
      return $.ajax({
        url: Routes.find_step_number_by_classroom_transfer_notes_pt_br_path({
          classroom_id: classroom_id,
          format: 'json'
        }),
        success: handleFetchStepByClassroomSuccess,
        error: handleFetchStepByClassroomError,
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
  }

  function handleFetchStepByClassroomError() {
    flashMessages.error('Ocorreu um erro ao buscar a etapa da turma.');
  }

  function fetchStudents() {
    var step_id = $step.select2('val');
    var recorded_at = $recordedAt.val();

    $student.select2({ data: [] });

    if (!_.isEmpty(recorded_at.match(dateRegex)) && !_.isEmpty(step_id)) {
      $.ajax({
        url: Routes.students_pt_br_path(),
        data: {
          classroom_id: $classroom.select2('val'),
          date: recorded_at,
          score_type: 'numeric',
          discipline_id: $discipline.select2('val'),
          step_id: step_id
        },
        success: handleFetchStudentsSuccess,
        error: handleFetchStudentsError
      });
    }
  };

  function handleFetchStudentsSuccess(data) {
    var filteredSelectedStudents = data.students.filter(function (student) {
      return !student['exempted_from_discipline'];
    });

    var selectedStudents = _.map(filteredSelectedStudents, function (student) {
      return { id: student['id'], text: student['name'] };
    });

    $student.select2({ data: selectedStudents });

    if (!selectedStudents.find(function (student) { return student.id == $student.select2('val') })) {
      $student.select2('val', '');
    }
  };

  function handleFetchStudentsError() {
    flashMessages.error('Ocorreu um erro ao buscar os alunos da turma selecionada.');
  };

  function fetchStudentOldNotes() {
    var step_id = $step.select2('val');
    var student_id = $student.select2('val');

    if (!_.isEmpty(step_id) && !_.isEmpty(student_id)) {
      $.ajax({
        url: Routes.old_notes_daily_note_students_pt_br_path(
          {
            classroom_id: $classroom.select2('val'),
            discipline_id: $discipline.select2('val'),
            step_id: step_id,
            student_id: student_id,
            format: 'json'
          }
        ),
        success: handlefetchStudentOldNotesSuccess,
        error: handlefetchStudentOldNotesError
      });
    }
  };

  function handlefetchStudentOldNotesSuccess(data) {
    if (!_.isEmpty(data.old_notes)) {
      $('.no_old_notes_found').hide();

      _.each(data.old_notes, function (old_note) {
        var html = JST['templates/transfer_notes/old_notes_row'](old_note);
        $('#old-notes-rows').append(html);
      });
    }
  };

  function handlefetchStudentOldNotesError() {
    flashMessages.error('Ocorreu um erro ao buscar as notas do aluno na turma anterior.');
  };

  function fetchStudentCurrentNotes() {
    var step_id = $step.select2('val');
    var student_id = $student.select2('val');
    var recorded_at = $recordedAt.val();

    if (!_.isEmpty(step_id) && !_.isEmpty(student_id) && !_.isEmpty(recorded_at.match(dateRegex))) {
      $.ajax({
        url: Routes.current_notes_transfer_notes_pt_br_path(
          {
            classroom_id: $classroom.select2('val'),
            discipline_id: $discipline.select2('val'),
            step_id: step_id,
            student_id: student_id,
            recorded_at: recorded_at,
            format: 'json'
          }
        ),
        success: handlefetchStudentCurrentNotesSuccess,
        error: handlefetchStudentCurrentNotesError
      });
    }
  };

  function handlefetchStudentCurrentNotesSuccess(data) {
    if (!_.isEmpty(data.transfer_notes)) {
      $('.no_current_notes_found').hide();
      var element_counter = 0;

      _.each(data.transfer_notes, function (current_note) {
        current_note.element_id = new Date().getTime() + element_counter++;
        var html = JST['templates/transfer_notes/current_notes_row'](current_note);
        $('#current-notes-rows').append(html);
      });

      $('#current-notes-rows input.decimal').inputmask('customDecimal');
    }
  };

  function handlefetchStudentCurrentNotesError() {
    flashMessages.error('Ocorreu um erro ao buscar as notas do aluno na turma atual.');
  };

  function removeStudentOldNotes() {
    $('#old-notes-rows').html('');
    $('.no_old_notes_found').show();
  }

  function removeStudentCurrentNotes() {
    $('#current-notes-rows').html('');
    $('.no_current_notes_found').show();
  }

  $('#transfer_note_copy_notes').on('click', function () {
    $('#old-notes-rows tr').each(function (i) {
      var note = $(this).find('td:eq(1)').text().trim();
      var recovery_note = $(this).find('td:eq(2)').text().trim();
      var $equivalentLine = $('#current-notes-rows tr:eq(' + i + ')');

      if ($equivalentLine.length) {
        if (note.length) {
          $equivalentLine.find('input[id$=_note]').val(note > recovery_note ? note : recovery_note);
        }
      }
    });

    return false;
  });

  function reset() {
    removeStudentOldNotes();
    removeStudentCurrentNotes();
    fetchStudentOldNotes();
    fetchStudentCurrentNotes();
  }

  $step.on('change', function () {
    reset();
    fetchStudents();
  });

  $recordedAt.on('change', function () {
    reset();
    fetchStudents();
  });

  $student.on('change', function () {
    reset();
  });

  if (!$('form[id^=edit_transfer_note]').length) {
    fetchStudentCurrentNotes();
  }

  fetchStudentOldNotes();
});
