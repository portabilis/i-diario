$(function () {
  'use strict';

  // Regular expression for dd/mm/yyyy date including validation for leap year and more
  var dateRegex = '^(?:(?:31(\\/)(?:0?[13578]|1[02]))\\1|(?:(?:29|30)(\\/)(?:0?[1,3-9]|1[0-2])\\2))(?:(?:1[6-9]|[2-9]\\d)?\\d{2})$|^(?:29(\\/)0?2\\3(?:(?:(?:1[6-9]|[2-9]\\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00))))$|^(?:0?[1-9]|1\\d|2[0-8])(\\/)(?:(?:0?[1-9])|(?:1[0-2]))\\4(?:(?:1[6-9]|[2-9]\\d)?\\d{2})$';

  var flashMessages = new FlashMessages();
  var $classroom = $('#transfer_note_classroom_id');
  var $discipline = $('#transfer_note_discipline_id');
  var $school_calendar_classroom_step = $('#transfer_note_school_calendar_classroom_step_id');
  var $transferDate = $('#transfer_note_transfer_date');
  var $student = $('#transfer_note_student_id');
  var schoolCalendarClassroomStep = null;


  function fetchDisciplines() {
    var classroom_id = $classroom.select2('val');

    $discipline.select2('val', '');
    $discipline.select2({ data: [] });

    if (!_.isEmpty(classroom_id)) {
      $.ajax({
        url: Routes.disciplines_pt_br_path({ classroom_id: classroom_id, format: 'json' }),
        success: handleFetchDisciplinesSuccess,
        error: handleFetchDisciplinesError
      });
    }
  };


  function fetchStudents() {
    var classroom_id = $classroom.select2('val');
    var transfer_date = $transferDate.val();

    $student.select2('val', '');
    $student.select2({ data: [] });

    if (!_.isEmpty(classroom_id) &&
        !_.isEmpty(transfer_date.match(dateRegex)) &&
        schoolCalendarClassroomStep &&
        !_.isEmpty(schoolCalendarClassroomStep.start_at) ) {
      $.ajax({
        url: Routes.students_pt_br_path(),
        data: {
          classroom_id: classroom_id,
          date: transfer_date,
          start_date: schoolCalendarClassroomStep.start_at,
          score_type: 'numeric',
          discipline_id: $discipline.select2('val'),
          school_calendar_step_id: schoolCalendarClassroomStep.id
        },
        success: handleFetchStudentsSuccess,
        error: handleFetchStudentsError
      });
    }
  };

  function handleFetchDisciplinesSuccess(disciplines) {
    var selectedDisciplines = _.map(disciplines, function(discipline) {
      return { id: discipline['id'], text: discipline['description'] };
    });

    $discipline.select2({ data: selectedDisciplines });
  };

  function handleFetchDisciplinesError() {
    flashMessages.error('Ocorreu um erro ao buscar as disciplinas da turma selecionada.');
  };

  function handleFetchStudentsSuccess(data) {
    var filteredSelectedStudents = data.students.filter(function(student) {
      return !student['exempted_from_discipline'];
    });

    var selectedStudents = _.map(filteredSelectedStudents, function(student) {
      return { id: student['id'], text: student['name'] };
    });

    $student.select2({ data: selectedStudents });
  };

  function handleFetchStudentsError() {
    flashMessages.error('Ocorreu um erro ao buscar os alunos da turma selecionada.');
  };

  function fetchSchoolCalendarClassroomStep() {
    var school_calendar_classroom_step_id = $school_calendar_classroom_step.select2('val');

    if (!_.isEmpty(school_calendar_classroom_step_id)) {
      $.ajax({
        url: Routes.school_calendar_classroom_step_pt_br_path(school_calendar_classroom_step_id, { format: 'json' }),
        success: handleFetchSchoolCalendarClassroomStepSuccess,
        error: handleFetchSchoolCalendarClassroomStepError
      });
    }
  }

  function handleFetchSchoolCalendarClassroomStepSuccess(data) {
    schoolCalendarClassroomStep = data;
    fetchStudents();
  };

  function handleFetchSchoolCalendarClassroomStepError() {
    flashMessages.error('Ocorreu um erro ao buscar a etapa selecionada.');
  };

  function fetchStudentOldNotes() {
    var classroom_id = $classroom.select2('val');
    var discipline_id = $discipline.select2('val');
    var school_calendar_classroom_step_id = $school_calendar_classroom_step.select2('val');
    var student_id = $student.select2('val');

    if (!_.isEmpty(classroom_id) &&
        !_.isEmpty(discipline_id) &&
        !_.isEmpty(school_calendar_classroom_step_id) &&
        !_.isEmpty(student_id)) {
      $.ajax({
        url: Routes.old_notes_classroom_steps_daily_note_students_pt_br_path({
            classroom_id: classroom_id,
            discipline_id: discipline_id,
            school_calendar_classroom_step_id: school_calendar_classroom_step_id,
            student_id: student_id,
            format: 'json'
          }),
        success: handlefetchStudentOldNotesSuccess,
        error: handlefetchStudentOldNotesError
      });
    }
  };

  function handlefetchStudentOldNotesSuccess(data) {
    if (!_.isEmpty(data.old_notes)) {
      $('.no_old_notes_found').hide();
      _.each(data.old_notes, function(old_note) {
        var html = JST['templates/transfer_notes/old_notes_row'](old_note);
        $('#old-notes-rows').append(html);
      });

    }
  };

  function handlefetchStudentOldNotesError() {
    flashMessages.error('Ocorreu um erro ao buscar as notas do aluno na turma anterior.');
  };

  function fetchStudentCurrentNotes(){
    var classroom_id = $classroom.select2('val');
    var discipline_id = $discipline.select2('val');
    var school_calendar_classroom_step_id = $school_calendar_classroom_step.select2('val');
    var student_id = $student.select2('val');
    var transfer_date = $transferDate.val();

    if (!_.isEmpty(classroom_id) &&
        !_.isEmpty(discipline_id) &&
        !_.isEmpty(school_calendar_classroom_step_id) &&
        !_.isEmpty(student_id) &&
        !_.isEmpty(transfer_date.match(dateRegex))) {
      $.ajax({
        url: Routes.current_notes_classroom_steps_transfer_notes_pt_br_path({
            classroom_id: classroom_id,
            discipline_id: discipline_id,
            school_calendar_classroom_step_id: school_calendar_classroom_step_id,
            student_id: student_id,
            transfer_date: transfer_date,
            format: 'json'
          }),
        success: handlefetchStudentCurrentNotesSuccess,
        error: handlefetchStudentCurrentNotesError
      });
    }
  };

  function handlefetchStudentCurrentNotesSuccess(data) {
    console.log(data);
    if (!_.isEmpty(data.transfer_notes)) {
      $('.no_current_notes_found').hide();
      var element_counter = 0;
      _.each(data.transfer_notes, function(current_note) {
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

  $('#transfer_note_copy_notes').on('click', function(){
    $('#old-notes-rows tr').each(function(i){
      var note = $(this).find('td:eq(1)').text().trim();
      var recovery_note = $(this).find('td:eq(2)').text().trim();
      var $equivalentLine = $('#current-notes-rows tr:eq('+i+')');

      if($equivalentLine.length){
        $equivalentLine.find('input[id$=_note]').val(note > recovery_note ? note : recovery_note);
      }
    });
    return false;
  });

  // On change

  $classroom.on('change', function() {
    fetchDisciplines();
    fetchStudents();
    removeStudentOldNotes();
    removeStudentCurrentNotes();
  });

  $discipline.on('change', function() {
    removeStudentOldNotes();
    removeStudentCurrentNotes();
    fetchStudentOldNotes();
  });

  $school_calendar_classroom_step.on('change', function () {
    fetchSchoolCalendarClassroomStep();
    removeStudentOldNotes();
    removeStudentCurrentNotes();
    fetchStudentOldNotes();
    fetchStudentCurrentNotes();
  });

  $transferDate.on('change', function() {
    removeStudentOldNotes();
    removeStudentCurrentNotes();
    fetchStudents();
    fetchStudentOldNotes();
    fetchStudentCurrentNotes();
  });

  $student.on('change', function() {
    removeStudentOldNotes();
    removeStudentCurrentNotes();
    fetchStudentOldNotes();
    fetchStudentCurrentNotes();
  });

  // On load
  fetchStudentOldNotes();
  if(!$('form[id^=edit_transfer_note]').length){
    fetchStudentCurrentNotes();
  }
});
