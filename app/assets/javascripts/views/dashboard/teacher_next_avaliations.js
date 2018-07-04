$(function(){
  "use strict";

  function fetchTeacherNextAvaliations() {
    $.ajax({
      beforeSend: function () {},
      complete: function () {},
      url: Routes.dashboard_teacher_next_avaliations_pt_br_path(),
      success: handleFetchTeacherNextAvaliationsSuccess,
      error: handleFetchTeacherNextAvaliationsError
    });
  };

  function handleFetchTeacherNextAvaliationsSuccess(data) {
    if(!_.isEmpty(data.teacher_next_avaliations)){
      $('#teacher-next-avaliations').html("");
    }
    _.each(data.teacher_next_avaliations, function(avaliation) {
      var html = JST['templates/teacher_dashboard/teacher_next_avaliations']({
        description: avaliation.to_s,
        classroom: avaliation.classroom.description,
        discipline: avaliation.discipline.description,
        test_date: avaliation.test_date_humanized,
        url_to_edit: Routes.edit_avaliation_pt_br_path(avaliation.id),
        url_to_post: Routes.daily_notes_pt_br_path({ daily_note: {avaliation_id: avaliation.id} }),
        test_date_today: avaliation.test_date_today
      });
      $('#teacher-next-avaliations').append(html);
    });

  }

  function handleFetchTeacherNextAvaliationsError() {
    flashMessages.error('Ocorreu um erro ao buscar as próximas avaliações do professor.');
  };

  fetchTeacherNextAvaliations();
});
