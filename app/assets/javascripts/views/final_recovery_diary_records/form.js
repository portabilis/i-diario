$(function () {
  'use strict';

  var flashMessages = new FlashMessages();
  var $classroom = $('#final_recovery_diary_record_recovery_diary_record_attributes_classroom_id');
  var $discipline = $('#final_recovery_diary_record_recovery_diary_record_attributes_discipline_id');

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

  function handleFetchDisciplinesSuccess(disciplines) {
    var selectedDisciplines = _.map(disciplines, function (discipline) {
      return { id: discipline['id'], text: discipline['description'] };
    });

    $discipline.select2({ data: selectedDisciplines });
  };

  function handleFetchDisciplinesError() {
    flashMessages.error('Ocorreu um erro ao buscar as disciplinas da turma selecionada.');
  };

  function fetchStudentsInFinalRecovery() {
    var classroom_id = $classroom.select2('val');
    var discipline_id = $discipline.select2('val');

    if (!_.isEmpty(classroom_id) &&
      !_.isEmpty(discipline_id)) {
      $.ajax({
        url: Routes.in_final_recovery_students_pt_br_path({
          classroom_id: classroom_id,
          discipline_id: discipline_id,
          format: 'json'
        }),
        success: handleFetchStudentsInFinalRecoverySuccess,
        error: handleFetchStudentsInFinalRecoveryError
      });
    }
  };

  function handleFetchStudentsInFinalRecoverySuccess(data) {
    var students = data.students
    if (!_.isEmpty(students)) {
      var element_counter = 0;

      hideNoItemMessage();

      _.each(students, function (student) {
        var element_id = new Date().getTime() + element_counter++

        var html = JST['templates/final_recovery_diary_records/student_fields']({
          id: student.id,
          name: student.name,
          needed_score: student.needed_score,
          element_id: element_id
        });

        $('#recovery-diary-record-students').append(html);
      });

      loadDecimalMasks();
    }
  };

  function handleFetchStudentsInFinalRecoveryError() {
    flashMessages.error('Ocorreu um erro ao buscar os alunos.');
  };

  function removeStudents() {
    // Remove not persisted students
    $('.nested-fields.dynamic').remove();

    // Hide persisted students and sets _destroy = true
    $('.nested-fields.existing').hide();
    $('.nested-fields.existing [id$=_destroy]').val(true);

    showNoItemMessage();
  }

  function hideNoItemMessage() {
    $('.no_item_found').hide();
  }

  function showNoItemMessage() {
    if (!$('.nested-fields').is(":visible")) {
      $('.no_item_found').show();
    }
  }

  function loadDecimalMasks() {
    var numberOfDecimalPlaces = $('#recovery-diary-record-students').data('scale');
    $('.nested-fields input.decimal, .needed_score').inputmask('customDecimal', { digits: numberOfDecimalPlaces });
  }

  // On change

  $classroom.on('change', function () {
    fetchDisciplines();
    removeStudents();

    // calendar final_recovery_diary_record_school_calendar_id
  });

  $discipline.on('change', function () {
    removeStudents();
    fetchStudentsInFinalRecovery();
  });

  // On load

  removeStudents();
  fetchStudentsInFinalRecovery();
  loadDecimalMasks();
});
