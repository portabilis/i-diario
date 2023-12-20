$(function () {
  'use strict';

  let flashMessages = new FlashMessages();
  let $unity = $('#attendance_record_report_by_student_form_unity_id');
  let $classroom = $('#attendance_record_report_by_student_form_classroom_id');

  $(document).ready(function() {
    getClassrooms();
    initializeForm();
  });

  $unity.on('change', function () {
    $classroom.val('').select2({ data: [] });
    getClassrooms();
  });

  function initializeForm() {
    if ($unity.val() === '' || $classroom.val() === '') {
      $('#send-form').attr("disabled", true);
    }

  }

  function getClassrooms() {
    const unity_id = $unity.select2('val');

    if (!_.isEmpty(unity_id)) {
      $.ajax({
        url: Routes.by_unity_classrooms_pt_br_path({
          unity_id: unity_id,
          format: 'json'
        }),
        success: handleFetchClassroomsSuccess,
        error: handleFetchClassroomsError
      });
    }
  }

  function handleFetchClassroomsSuccess(data) {
    let classrooms = _.map(data.classrooms, function(classroom) {
      return { id: classroom.table.id, name: classroom.table.name, text: classroom.table.text };
    });
    classrooms.unshift({ id: 'all', name: '<option>Todas</option>', text: 'Todas' });
    $classroom.select2({ data: classrooms })
  }

  function handleFetchClassroomsError() {
    flashMessages.error('Ocorreu um erro ao buscar as turmas da escola selecionada.');
  }

  $classroom.on('change', function() {
    if ($unity.val() !== '' && $classroom.val() !== '') {
      $('#send-form').attr("disabled", false);
    }
  });

});
