$(function(){
  "use strict";

  var flashMessages = new FlashMessages();

  var $parentSchoolCalendarStep = $('.parent_school_calendar_step');

  function fetchPartialScores() {
    var studentId = $(this).attr('data-student')
    var classroomId = $(this).attr('data-classroom')
    var schoolCalendarStepId = $(this).val();
    var $scoresTbody = $(this).closest(".parent-dashboard-partial-scores-container")
                              .find(".parent_partial_scores_tbody")
                              .first();
    console.log("fetchPartialScores Called!");
    console.log("fetchPartialScores studentId:"+studentId);
    console.log("fetchPartialScores classroomId:"+classroomId);
    console.log("fetchPartialScores schoolCalendarStepId:"+schoolCalendarStepId);

    if (!_.isEmpty(studentId) && !_.isEmpty(schoolCalendarStepId)){
      $.ajax({
        url: Routes.dashboard_student_partial_scores_pt_br_path(
          {
            format: 'json',
            student_id: studentId,
            classroom_id: classroomId,
            school_calendar_step_id: schoolCalendarStepId
          }
        ),
        success: function(data){
          handleFetchPartialScoresSuccess(data, $scoresTbody);
        },
        error: handleFetchPartialScoresError
      });
    }
  };

  function handleFetchPartialScoresSuccess(data, $scoresTbody) {

    $scoresTbody.html("");

    if(_.isEmpty(data.student_partial_scores)){
      $scoresTbody.append("<tr><td class=no_record_found colspan=5>Nenhuma avaliação cadastrada.</td></tr>")
    }

    _.each(data.student_partial_scores, function(record) {
      var html = JST['templates/parent_dashboard/partial_scores_tbody']({
        avaliation: record.avaliation,
        date: record.date,
        discipline: record.discipline,
        weight: record.weight,
        score: record.score || "<span class='gray'>Não informado</span>"
      });
      $scoresTbody.append(html);
    });

  }

  function handleFetchPartialScoresError() {
    flashMessages.error('Ocorreu um erro ao buscar as avaliações parciais do aluno.');
  };

  $.each($parentSchoolCalendarStep, function(){
    $(this).on('change', fetchPartialScores).trigger("change");
    console.log("loop");
    console.log($(this));
  });
  console.log("partial_scores loaded");
});
