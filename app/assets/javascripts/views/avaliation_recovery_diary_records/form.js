$(function () {
  'use strict';

  var flashMessages = new FlashMessages();
  var $classroom = $('#avaliation_recovery_diary_record_recovery_diary_record_attributes_classroom_id');
  var $discipline = $('#avaliation_recovery_diary_record_recovery_diary_record_attributes_discipline_id');
  var $avaliation = $('#avaliation_recovery_diary_record_avaliation_id');
  var $recorded_at = $('#avaliation_recovery_diary_record_recovery_diary_record_attributes_recorded_at');

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

  function fetchAvaliations() {
    var classroom_id = $classroom.select2('val');
    var discipline_id = $discipline.select2('val');

    $avaliation.select2('val', '');
    $avaliation.select2({ data: [] });

    if (!_.isEmpty(classroom_id) && !_.isEmpty(discipline_id)) {
      $.ajax({
        url: Routes.search_avaliations_pt_br_path({
          filter: {
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

  function handleFetchAvaliationsSuccess(data) {
    var selectedAvaliations = _.map(data.avaliations, function (avaliation) {
      return { id: avaliation['id'], text: avaliation['description_to_teacher'] };
    });

    $avaliation.select2({ data: selectedAvaliations });
    flashMessages.success('Avaliação selecionada com sucesso.');
  };


  function handleFetchAvaliationsError() {
    flashMessages.error('Ocorreu um erro ao buscar as avaliações da turma selecionada.');
  };

  function fetchStudents() {
    var avaliation_id = $avaliation.select2('val');
    var recorded_at = $recorded_at.val();

    if (!isValidDate(recorded_at)) {
      return;
    }

    if (!_.isEmpty(avaliation_id) && !_.isEmpty(recorded_at)) {
      $.ajax({
        url: Routes.dependence_daily_note_students_pt_br_path({
          filter: {
            by_avaliation: avaliation_id
          },
          search: {
            recorded_at: recorded_at
          },
          format: 'json'
        }),
        success: handleFetchStudentsSuccess,
        error: handleFetchStudentsError
      });
    }
  };

  function handleFetchStudentsSuccess(data) {
    $('#recovery-diary-record-students').empty();

    if (_.isEmpty(data)) {
      $recorded_at.val($recorded_at.data('oldDate'));

      flashMessages.error('Nenhum aluno encontrado.');
    } else {
      var daily_note_students = data.daily_note_students

      if (!_.isEmpty(daily_note_students)) {
        var element_counter = 0;
        var existing_ids = [];
        var fetched_ids = [];

        hideNoItemMessage();

        $('#recovery-diary-record-students').children('tr').each(function () {
          if (!$(this).hasClass('destroy')) {
            existing_ids.push(parseInt(this.id));
          }
        });
        existing_ids.shift();

        if (_.isEmpty(existing_ids)) {
          _.each(daily_note_students, function (daily_note_student) {
            var element_id = new Date().getTime() + element_counter++;

            buildStudentField(element_id, daily_note_student);
          });

          loadDecimalMasks();
        } else {
          $.each(daily_note_students, function (index, daily_note_student) {
            var fetched_id = daily_note_student.id;

            fetched_ids.push(fetched_id);

            if ($.inArray(fetched_id, existing_ids) == -1) {
              if ($('#' + fetched_id).length != 0 && $('#' + fetched_id).hasClass('destroy')) {
                restoreStudent(fetched_id);
              } else {
                var element_id = new Date().getTime() + element_counter++;

                buildStudentField(element_id, daily_note_student, index);
              }
              existing_ids.push(fetched_id);
            }
          });

          loadDecimalMasks();

          _.each(existing_ids, function (existing_id) {
            if ($.inArray(existing_id, fetched_ids) == -1) {
              removeStudent(existing_id);
            }
          });
        }
      } else {
        $recorded_at.val($recorded_at.data('oldDate'));

        flashMessages.error('Nenhum aluno encontrado.');
      }
    }
  };

  function handleFetchStudentsError() {
    flashMessages.error('Ocorreu um erro ao buscar os alunos.');
  };

  function buildStudentField(element_id, daily_note_student, index = null) {
    var student_situation = 'multiline ';
    var student_name;

    if (daily_note_student.exempted_from_discipline) {
      student_situation = student_situation + 'exempted-student-from-discipline';
      student_name = '****' + daily_note_student.name
    } else if (!daily_note_student.active) {
      student_situation = student_situation + 'inactive-student';
      student_name = '***' + daily_note_student.name
    } else if (daily_note_student.dependence) {
      student_situation = student_situation + 'dependence-student';
      student_name = '*' + daily_note_student.name
    } else if (daily_note_student.in_active_search) {
      student_situation = student_situation + 'in-active-search';
      student_name = '*****' + daily_note_student.name
    } else {
      student_name = daily_note_student.name
    }

    var html = JST['templates/avaliation_recovery_diary_records/student_fields']({
      sequence: daily_note_student.sequence,
      id: daily_note_student.id,
      name: student_name,
      note: daily_note_student.note,
      student_situation: student_situation,
      active: daily_note_student.active,
      element_id: element_id,
      exempted_from_discipline: daily_note_student.exempted_from_discipline
    });

    var $tbody = $('#recovery-diary-record-students');

    if ($.isNumeric(index)) {
      $(html).insertAfter($tbody.children('tr')[index]);
    } else {
      $tbody.append(html);
    }
  }

  function removeStudent(id) {
    $('#' + id).hide();
    $('#' + id).addClass('destroy');
    $('.nested-fields#' + id + ' [id$=_destroy]').val(true);
  }

  function restoreStudent(id) {
    $('#' + id).show();
    $('#' + id).removeClass('destroy');
    $('.nested-fields#' + id + ' [id$=_destroy]').val(false);
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
  $classroom.on('change', function () {
    showNoItemMessage();
    fetchDisciplines();

    $avaliation.prop('readonly', true);
    $recorded_at.val(null).trigger('change');
  });

  $discipline.on('change', function () {
    fetchAvaliations();

    if (_.isEmpty($avaliation.val())) {
      flashMessages.error('A turma selecionada não está configurada para utilizar este recurso.');
    }

    $avaliation.prop('readonly', false);
    $recorded_at.val(null).trigger('change');
  });

  $avaliation.on('change', function () {
    if (!_.isEmpty($recorded_at.val())) {
      showNoItemMessage();
      fetchStudents();
    }
  });

  $recorded_at.on('focusin', function () {
    $(this).data('oldDate', $(this).val());
  });

  $recorded_at.on('change', function () {
    if (!_.isEmpty($avaliation.select2('val'))) {
      showNoItemMessage();
      fetchStudents();
    }
  });

  // On load
  fetchAvaliations();
  loadDecimalMasks();
});
