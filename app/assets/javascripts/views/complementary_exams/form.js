$(function () {
  'use strict';

  var flashMessages = new FlashMessages();
  var $classroom = $('#complementary_exam_classroom_id');
  var $discipline = $('#complementary_exam_discipline_id');
  var $setting = $('#complementary_exam_complementary_exam_setting_id');
  var $step = $('#complementary_exam_step_id');
  var $recorded_at = $('#complementary_exam_recorded_at');
  var with_recovery_note_in_step = false;
  var save_button = document.getElementById('exam-save');

  function fetchSettings() {
    var classroom_id = $classroom.val();
    var discipline_id = $discipline.val();
    var step_id = $step.select2('val');

    $setting.select2('val', '');
    $setting.select2({ data: [] });

    if (!_.isEmpty(classroom_id) && !_.isEmpty(discipline_id) && !_.isEmpty(step_id)) {
      var parameters = {
        classroom_id: classroom_id,
        discipline_id: discipline_id,
        step_id: step_id
      };

      $.getJSON(Routes.settings_complementary_exams_pt_br_path(), parameters)
        .success(handleFetchSettingsSuccess)
        .fail(handleFetchSettingsError);
    }
  };

  function handleFetchSettingsSuccess(data) {
    if (_.isEmpty(data['complementary_exams'])) {
      save_button.disabled = true;
      flashMessages.error('A turma selecionada não foi configurada para avaliações complementares');
    } else {
      var selectedSettings = _.map(data.complementary_exams, function (setting) {
        return { id: setting['id'], text: setting['description'] };
      });

      $setting.select2({ data: selectedSettings });
      $setting.val(selectedSettings[0].id).trigger('change');
      save_button.disabled = false;
    }
  };

  function handleFetchSettingsError() {
    flashMessages.error('Ocorreu um erro ao buscar as avaliações complementares da etapa selecionada.');
  };

  function fetchSettingInfo() {
    var id = $setting.select2('val');

    if (!_.isEmpty(id)) {
      $.getJSON(Routes.complementary_exam_setting_pt_br_path({ id: id }))
        .success(handleFetchSettingInfoSuccess)
        .fail(handleFetchSettingInfoError);
    }
  };

  function handleFetchSettingInfoSuccess(data) {
    $('#complementary-exam-students').attr('data-scale', data.complementary_exam_setting.number_of_decimal_places);
    with_recovery_note_in_step = data.complementary_exam_setting.affected_score == 'step_recovery_score';
    if (!_.isEmpty($recorded_at.val())) {
      fetchStudents();
    }
  };

  function handleFetchSettingInfoError() {
    flashMessages.error('Ocorreu um erro ao buscar informações da avaliação informada.');
  };

  function fetchStudents() {
    var discipline_id = $discipline.val();
    var classroom_id = $classroom.val();
    var recorded_at = $recorded_at.val();

    if (!_.isEmpty(discipline_id) && !_.isEmpty(classroom_id) && !_.isEmpty(recorded_at)) {
      $.ajax({
        url: Routes.fetch_students_complementary_exams_pt_br_path({
          classroom_id: classroom_id,
          discipline_id: discipline_id,
          date: recorded_at,
          with_recovery_note_in_step: with_recovery_note_in_step,
          format: 'json'
        }),
        success: handleFetchStudentsSuccess,
        error: handleFetchStudentsError
      });
    }
  };

  // Matrículas de dependência ficam após as matrículas regulares, com sequencial próprio: a
  // numeração dos dependentes reinicia em 1 (independente da numeração dos regulares).
  function sortEnrollmentsForDependence(student_enrollments_lists) {
    var normals = [];
    var dependents = [];

    _.each(student_enrollments_lists, function (student_enrollment) {
      if (student_enrollment.in_dependence) {
        dependents.push(student_enrollment);
      } else {
        normals.push(student_enrollment);
      }
    });

    normals.forEach(function (enrollment, index) { enrollment.sequence = index + 1; });
    dependents.forEach(function (enrollment, index) { enrollment.sequence = index + 1; });

    return normals.concat(dependents);
  }

  function handleFetchStudentsSuccess(data) {
    var student_enrollments_lists = sortEnrollmentsForDependence(data.students);

    if (!_.isEmpty(student_enrollments_lists)) {
      hideNoItemMessage();

      var element_counter = 0;
      var existing_ids = [];
      var fetched_ids = [];

      $('#complementary-exam-students').children('tr').each(function () {
        if (!$(this).hasClass('destroy')) {
          existing_ids.push(parseInt(this.id));
        }
      });
      existing_ids.shift();

      if (_.isEmpty(existing_ids)) {
        _.each(student_enrollments_lists, function (student_enrollment) {
          var element_id = new Date().getTime() + element_counter++;

          buildStudentField(element_id, student_enrollment);
        });

        loadDecimalMasks();
      } else {
        $.each(student_enrollments_lists, function (index, student_enrollment) {
          var fetched_id = student_enrollment.student.id;

          fetched_ids.push(fetched_id);

          if ($.inArray(fetched_id, existing_ids) == -1) {
            if ($('#' + fetched_id).length != 0 && $('#' + fetched_id).hasClass('destroy')) {
              restoreStudent(fetched_id);
            } else {
              var element_id = new Date().getTime() + element_counter++;

              buildStudentField(element_id, student_enrollment, index);
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

      updateStatusLegend();
    } else {
      $recorded_at.val($recorded_at.data('oldDate'));

      if (with_recovery_note_in_step) {
        flashMessages.error('Nenhum aluno encontrado, verifique se existe recuperação de etapa lançada para etapa informada.');
      } else {
        flashMessages.error('Nenhum aluno encontrado para os filtros informados.');
      }
    }
  };

  function handleFetchStudentsError() {
    flashMessages.error('Ocorreu um erro ao buscar os alunos.');
  };

  // Aluno com mais de uma matrícula na turma tem uma linha por matrícula, todas com o id do aluno;
  // $('#id') pegaria só a primeira.
  function studentRows(id) {
    return $('#complementary-exam-students tr.nested-fields').filter(function () {
      return this.id === String(id);
    });
  }

  function removeStudent(id) {
    var $rows = studentRows(id);

    $rows.hide();
    $rows.addClass('destroy');
    $rows.find('[id$=_destroy]').val(true);
  }

  function restoreStudent(id) {
    var $rows = studentRows(id);

    $rows.show();
    $rows.removeClass('destroy');
    $rows.find('[id$=_destroy]').val(false);
  }

  // Revela na legenda apenas as situações com badge presente na tabela.
  function updateStatusLegend() {
    var statuses = ['inactive', 'dependence', 'exempted-from-discipline', 'active-search'];
    var anyVisible = false;

    statuses.forEach(function (status) {
      var hasBadge = $('#complementary-exam-students tr.nested-fields:not(.destroy) .badge-status--' + status).length > 0;
      $('.student-status-legend__item[data-status="' + status + '"]').toggle(hasBadge);
      if (hasBadge) { anyVisible = true; }
    });

    $('.student-status-legend').toggle(anyVisible);
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
    var numberOfDecimalPlaces = parseInt($('#complementary-exam-students').attr('data-scale')) || 0;
    $('.nested-fields input.decimal').inputmask('customDecimal', { digits: numberOfDecimalPlaces });
  }

  $(document).on('keydown', '.nested-fields input.decimal', function(e) {
    if (e.keyCode === 13) {
      e.preventDefault();
      var inputs = $('.nested-fields input.decimal:not([readonly])');
      var currentIndex = inputs.index(this);

      if (currentIndex < inputs.length - 1) {
        inputs.eq(currentIndex + 1).focus();
      }
    }
  });

  function buildStudentField(element_id, student_enrollment, index = null) {
    var student = student_enrollment.student;
    var active = !student_enrollment.inactive_on_date;
    var in_active_search = !!student_enrollment.in_active_search;
    var exempted_from_discipline = !!student_enrollment.exempted_from_discipline;
    var dependence = !!student_enrollment.in_dependence;
    var status_badge = '';

    if (in_active_search) {
      status_badge = renderStudentStatusBadge('active-search');
    } else if (!active) {
      status_badge = renderStudentStatusBadge('inactive');
    } else if (dependence) {
      status_badge = renderStudentStatusBadge('dependence');
    } else if (exempted_from_discipline) {
      status_badge = renderStudentStatusBadge('exempted-from-discipline');
    }

    var html = JST['templates/complementary_exams/student_fields']({
      id: student.id,
      name: student.name,
      element_id: element_id,
      sequence: student_enrollment.sequence,
      status_badge: status_badge,
      active: active,
      exempted_from_discipline: exempted_from_discipline,
      in_active_search: in_active_search
    });

    var $tbody = $('#complementary-exam-students');

    if ($.isNumeric(index)) {
      $(html).insertAfter($tbody.children('tr')[index]);
    } else {
      $tbody.append(html);
    }
  }

  $classroom.on('change', function () {
    var classroom_id = $classroom.select2('val');

    if (!_.isEmpty(classroom_id)) {
      fetchDisciplines(classroom_id);
      getStep(classroom_id);
    } else {
      // Limpa o campo de etapa e disciplina
      $discipline.select2({ data: [] });
      $step.select2({ data: [] });
    }
  });

  $step.on('change', function () {
    fetchSettings();
  });

  $setting.on('change', function () {
    fetchSettingInfo();
  });

  $recorded_at.on('focusin', function () {
    $(this).data('oldDate', $(this).val());
  });

  $recorded_at.on('change', function () {
    if (!_.isEmpty($setting.select2('val'))) {
      showNoItemMessage();
      fetchStudents();
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

  function getStep(classroom_id) {
    return $.ajax({
      url: Routes.fetch_step_school_term_recovery_diary_records_pt_br_path({
        classroom_id: classroom_id,
        format: 'json'
      }),
      success: handleFetchStepByClassroomSuccess,
      error: handleFetchStepByClassroomError
    });
  }

  function handleFetchStepByClassroomSuccess(data) {
    if (data) {
      let selectedSteps = data.map(function (step) {
        return { id: step['id'], text: step['description'] };
      });

      $step.select2({ data: selectedSteps });

      // Define a primeira opção como selecionada por padrão
      $step.val(selectedSteps[0].id).trigger('change');
    }
  };

  function handleFetchStepByClassroomError() {
    flashMessages.error('Ocorreu um erro ao buscar a etapa da turma.');
  };

  // On load
  loadDecimalMasks();
  updateStatusLegend();

  if (_.isEmpty($setting.val())) {
    save_button.disabled = true;
  }
});
