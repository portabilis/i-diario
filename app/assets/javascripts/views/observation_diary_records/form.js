$(function () {
  'use strict';

  var flashMessages = new FlashMessages();
  var $classroom = $('#observation_diary_record_classroom_id');
  var $discipline = $('#observation_diary_record_discipline_id');
  var $disciplineDiv = $("[data-discipline]");
  var $disciplineContainer = $('.observation_diary_record_discipline');
  var $date = $('#observation_diary_record_date');
  var $observationDiaryRecordNotesContainer = $('#observation-diary-record-notes');
  var $observationDiaryRecordAttachmentsContainer = $('#observation-diary-record-attachments');
  var students = [];

  function onChangeFileElement(){
    if (this.files[0].size > 3145728) {
      $(this).closest(".control-group").find('span').remove();
      $(this).closest(".control-group").addClass("error");
      $(this).after('<span class="help-inline">tamanho máximo por arquivo: 3 MB</span>');
      $(this).val("");
    }else {
      $(this).closest(".control-group").removeClass("error");
      $(this).closest(".control-group").find('span').remove();
    }
  }

  $(".observation_diary_attachment").on('change', onChangeFileElement);

  $('#observation_diary_records_form').on('cocoon:after-insert', function(e, item) {
    $(item).find('input.file').on('change', onChangeFileElement);
  });

  function loadStudentsSelect2() {
    var $studentsInputs = $('input[id$=student_ids]')
    $studentsInputs.select2({ data: students, multiple: true });
  }

  function fetchDisciplines() {
    var classroom_id = $classroom.select2('val');

    $discipline.select2({ data: [] });

    if (!_.isEmpty(classroom_id)) {
      $.ajax({
        url: Routes.disciplines_pt_br_path({ classroom_id: classroom_id, format: 'json' }),
        success: handleFetchDisciplinesSuccess,
        error: handleFetchDisciplinesError
      });
    }
  }

  function handleFetchDisciplinesSuccess(disciplines) {
    var selectedDisciplines = _.map(disciplines, function(discipline) {
      return { id: discipline['id'], text: discipline['description'] };
    });

    $discipline.select2({ data: selectedDisciplines });
  }

  function handleFetchDisciplinesError() {
    flashMessages.error('Ocorreu um erro ao buscar as disciplinas da turma selecionada.');
  }

  function fetchStudents() {
    var classroom_id = $classroom.select2('val');
    var date = $date.val();

    if (!_.isEmpty(classroom_id) && !_.isEmpty(date)) {
      $.ajax({
        url: Routes.classroom_students_pt_br_path({ classroom_id: classroom_id, date: date, format: 'json' }),
        success: handleFetchStudentsSuccess,
        error: handleFetchStudentsError
      });
    }
  }

  function handleFetchStudentsSuccess(data) {
    students = _.map(data.students, function(student) {
      return { id: student.id, text: student.name };
    });

    loadStudentsSelect2();
  }

  function handleFetchStudentsError() {
    flashMessages.error('Ocorreu um erro ao buscar os alunos da turma selecionada.');
  }

  // On change

  $classroom.on('change', function() {
    fetchDisciplines();
    fetchStudents();
  });

  $date.on('valid-date', function() {
    fetchStudents();
  });

  // On after add note
  $observationDiaryRecordNotesContainer.on('cocoon:after-insert', function(e, item) {
    // Workaround to correctly load students select2
    setTimeout(loadStudentsSelect2, 50);
  });

  //On after add attachment
  $observationDiaryRecordAttachmentsContainer.on('cocoon:after-insert', function(e, item) {
    // Workaround to correctly load students select2
    setTimeout(loadStudentsSelect2, 50);
  });

  // On load
  fetchDisciplines();
  fetchStudents();
});
