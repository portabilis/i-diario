$(function () {
  'use strict';

  var flashMessages = new FlashMessages();
  var $classroom = $('#avaliation_recovery_diary_record_recovery_diary_record_attributes_classroom_id');
  var $discipline = $('#avaliation_recovery_diary_record_recovery_diary_record_attributes_discipline_id');
  var $avaliation = $('#avaliation_recovery_diary_record_avaliation_id');

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

  function fetchAvaliations() {
    var classroom_id = $classroom.select2('val');
    var discipline_id = $discipline.select2('val');

    $avaliation.select2('val', '');
    $avaliation.select2({ data: [] });

    if (!_.isEmpty(classroom_id) && !_.isEmpty(discipline_id)) {
      $.ajax({
        url: Routes.avaliations_pt_br_path({filter: {
                                              by_classroom_id: classroom_id,
                                              by_discipline_id: discipline_id
                                            },
                                            format: 'json'
                                            }),
        success: handleFetchAvaliationsSuccess,
        error: handleFetchAvaliationsError
      });
    }
  };

  function handleFetchDisciplinesSuccess(disciplines) {
    var selectedDisciplines = _.map(disciplines, function(discipline) {
      return { id: discipline['id'], text: discipline['description'] };
    });

    $discipline.select2({ data: selectedDisciplines });
  };

  function handleFetchAvaliationsSuccess(data) {
    var selectedAvaliations = _.map(data.avaliations, function(avaliation) {
      return { id: avaliation['id'], text: avaliation['description_to_teacher'] };
    });

    $avaliation.select2({ data: selectedAvaliations });
  };

  function handleFetchDisciplinesError() {
    flashMessages.error('Ocorreu um erro ao buscar as disciplinas da turma selecionada.');
  };

  function handleFetchAvaliationsError() {
    flashMessages.error('Ocorreu um erro ao buscar as avaliações da turma selecionada.');
  };

  function fetchStudents() {
    var avaliation_id = $avaliation.select2('val');

    if (!_.isEmpty(avaliation_id)){
      $.ajax({
        url: Routes.daily_note_students_pt_br_path({
            filter: {
                by_avaliation: avaliation_id
            },
            format: 'json'
          }),
        success: handleFetchStudentsSuccess,
        error: handleFetchStudentsError
      });
    }
  };

  function handleFetchStudentsSuccess(data) {
    var daily_note_students = data.daily_note_students
    if (!_.isEmpty(daily_note_students)) {
      var element_counter = 0;

      hideNoItemMessage();

      _.each(daily_note_students, function(daily_note_student) {
        var element_id = new Date().getTime() + element_counter++

        var html = JST['templates/avaliation_recovery_diary_records/student_fields']({
            id: daily_note_student.student.id,
            name: daily_note_student.student.name,
            note: daily_note_student.note,
            element_id: element_id
          });

        $('#recovery-diary-record-students').append(html);
      });

      loadDecimalMasks();
    }
  };

  function handleFetchStudentsError() {
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

  function hideNoItemMessage() {
    $('.no_item_found').hide();
  }

  function showNoItemMessage() {
    if (!$('.nested-fields').is(":visible")) {
      $('.no_item_found').show();
    }
  }

  function loadDecimalMasks() {
    var numberOfDecimalPlaces = parseInt($('#recovery-diary-record-students').data('scale')) || 0;
    $('.nested-fields input.decimal, .note').inputmask('customDecimal', { digits: numberOfDecimalPlaces });
  }

  // On change
  $classroom.on('change', function() {
    fetchDisciplines();
    removeStudents();
  });

  $discipline.on('change', function() {
    fetchAvaliations();
  });
  $avaliation.on('change', function() {
    removeStudents();
    fetchStudents();
  });

  // On load
  fetchDisciplines();
  fetchAvaliations();
  loadDecimalMasks();
});
