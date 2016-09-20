$(function () {
  'use strict';

  var $classrooms = $("#knowledge_area_lesson_plan_cloner_form_classroom_ids");
  var $knowledgeAreaLessonPlan = $("#knowledge_area_lesson_plan_cloner_form_knowledge_area_lesson_plan_id");

  $('a.open_copy_modal').on('click', function(){

    var $row = $(this).closest('tr');
    var knowledge_area_lesson_plan_id = $(this).data('knowledge-area-lesson-plan-id');
    var classroom_id = $(this).data('classroom-id');
    var grade_id = $(this).data('grade-id');

    $classrooms.select2("val", "");
    $knowledgeAreaLessonPlan.val(knowledge_area_lesson_plan_id);
    $classrooms.closest(".control-group").removeClass("error");
    $classrooms.closest(".control-group").find("span.help-inline").remove();

    var classroom = $row.find(".classroom").text();
    var knowledge_area = $row.find(".knowledge_area").html();
    var start_at = $row.find(".start_at").text();
    var end_at = $row.find(".end_at").text();

    $("#copy-knowledge-area-lesson-plan-modal table tbody td.classroom").text(classroom);
    $("#copy-knowledge-area-lesson-plan-modal table tbody td.knowledge_area").html(knowledge_area);
    $("#copy-knowledge-area-lesson-plan-modal table tbody td.start_at").text(start_at);
    $("#copy-knowledge-area-lesson-plan-modal table tbody td.end_at").text(end_at);
    $("#copy-knowledge-area-lesson-plan-modal").modal('show');

    var params = {
      filter: {
        by_grade: grade_id,
        different_than: classroom_id
      },
      find_by_current_teacher: true
    };

    $.getJSON(Routes.classrooms_pt_br_path(params)).always(function (data) {
      var selectedClassrooms = _.map(data, function(classroom) {
        return { id: classroom['id'], text: classroom['description'] };
      });

      $classrooms.select2({ data: selectedClassrooms, multiple: true });
    });

  });
});
