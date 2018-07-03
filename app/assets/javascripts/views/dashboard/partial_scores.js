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

    if (!_.isEmpty(studentId) && !_.isEmpty(schoolCalendarStepId)){
      $.ajax({
        beforeSend: function () {},
        complete: function () {},
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
      $scoresTbody.append("<tr><td class=no_record_found colspan=5>Nenhuma avaliação definida para a etapa selecionada.</td></tr>")
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

    makeColumnsWidth($scoresTbody.closest('.parent-dashboard-partial-scores-container'));

  }

  function handleFetchPartialScoresError() {
    flashMessages.error('Ocorreu um erro ao buscar as avaliações parciais do aluno.');
  };

  $.each($parentSchoolCalendarStep, function(){
    $(this).on('change', fetchPartialScores).trigger("change");
  });

  var makeColumnsWidth = function($container){
    var headerCells = $container.find('thead')[0].rows[0].cells;
    var dataCells = $container.find('tbody')[0].rows[0].cells;

    var scrollbarWidth = $container.find('.table-responsive')[1].offsetWidth - $container.find('.table-responsive')[1].clientWidth;

    if(dataCells.length > 1){
      for (var i = 0; i < dataCells.length; i++){
        var cellWidth = i == dataCells.length-1 ? dataCells[i].offsetWidth+scrollbarWidth : dataCells[i].offsetWidth;
        headerCells[i].style.width = cellWidth + 'px';
      }
    }
  }

  $.each($(".parent-dashboard-partial-scores-container"), function(){
    makeColumnsWidth($(this));
  });

  $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
    var target = $(e.target).attr("href") // activated tab
    makeColumnsWidth($(target).find(".parent-dashboard-partial-scores-container"));
  });

});
