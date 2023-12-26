$(function(){
  "use strict"

  $('#lesson-plan-report').on('click', function(e){
    e.preventDefault();
    $('#discipline-lesson-plan-report-form').attr('action', 
      Routes.discipline_lesson_plan_report_pt_br_path()
    );
    $('#discipline-lesson-plan-report-form').submit();
  });

  $('#content-record-report').on('click', function(e){
    e.preventDefault();
    $('#discipline-lesson-plan-report-form').attr('action', 
      Routes.discipline_content_record_report_pt_br_path()
    );
    $('#discipline-lesson-plan-report-form').submit();
  });
});
