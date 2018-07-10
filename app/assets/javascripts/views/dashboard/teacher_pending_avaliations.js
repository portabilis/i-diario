$(function(){
  "use strict";

  var flashMessages = new FlashMessages();

  var $schoolCalendarStepElement = $('#school_calendar_step_pending_avaliations');

  $schoolCalendarStepElement.on('change', fetchTeacherPendingAvaliations);

  function fetchTeacherPendingAvaliations() {
    var schoolCalendarStepId = $schoolCalendarStepElement.val();

    if (!_.isEmpty(schoolCalendarStepId)){
      $.ajax({
        beforeSend: function () {},
        complete: function () {},
        url: Routes.dashboard_teacher_pending_avaliations_pt_br_path(
          {
            format: 'json',
            school_calendar_step_id: schoolCalendarStepId
          }
        ),
        success: handleFetchTeacherPendingAvaliationsSuccess,
        error: handleFetchTeacherPendingAvaliationsError
      });
    }
  };

  function handleFetchTeacherPendingAvaliationsSuccess(data) {
    $('#teacher-pending-avaliations').html("");

    if(_.isEmpty(data.teacher_pending_avaliations)){
      $('#teacher-pending-avaliations').append("<tr><td class=no_record_found colspan=5>Nenhuma avaliação pendente.</td></tr>")
    }
    _.each(data.teacher_pending_avaliations, function(avaliation) {
      var html = JST['templates/teacher_dashboard/teacher_pending_avaliations']({
        description: avaliation.to_s,
        classroom: avaliation.classroom.description,
        discipline: avaliation.discipline.description,
        test_date: avaliation.test_date_humanized,
        url_to_edit: Routes.edit_avaliation_pt_br_path(avaliation.id),
        url_to_post: Routes.daily_notes_pt_br_path({ daily_note: {avaliation_id: avaliation.id} })
      });
      $('#teacher-pending-avaliations').append(html);
    });

  }

  function handleFetchTeacherPendingAvaliationsError() {
    flashMessages.error('Ocorreu um erro ao buscar as avaliações pendentes do professor.');
  };

  fetchTeacherPendingAvaliations();

});
