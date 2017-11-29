$(function(){
  "use strict"

  $('#lesson-plan-report').on('click', function(e){
    e.preventDefault();
    $('#knowledge-area-lesson-plan-report-form').attr('action', Routes.knowledge_area_lesson_plan_report_pt_br_path());
    $('#knowledge-area-lesson-plan-report-form').submit();
  });

  $('#content-record-report').on('click', function(e){
    e.preventDefault();
    $('#knowledge-area-lesson-plan-report-form').attr('action', Routes.knowledge_area_content_record_report_pt_br_path());
    $('#knowledge-area-lesson-plan-report-form').submit();
  });
});
