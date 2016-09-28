$(function () {
  'use strict';

  var $classrooms = $("#discipline_lesson_plan_cloner_form_classroom_ids");
  var $disciplineLessonPlan = $("#discipline_lesson_plan_cloner_form_discipline_lesson_plan_id");

  $(document).on('click', 'a.open_copy_modal', function(){

    var $row = $(this).closest('tr');
    var discipline_lesson_plan_id = $(this).data('discipline-lesson-plan-id');
    var discipline_id = $(this).data('discipline-id');
    var classroom_id = $(this).data('classroom-id');
    var grade_id = $(this).data('grade-id');

    $classrooms.select2("val", "");
    $disciplineLessonPlan.val(discipline_lesson_plan_id);
    $classrooms.closest(".control-group").removeClass("error");
    $classrooms.closest(".control-group").find("span.help-inline").remove();

    var classroom = $row.find(".classroom").text();
    var discipline = $row.find(".discipline").text();
    var start_at = $row.find(".start_at").text();
    var end_at = $row.find(".end_at").text();

    $("#copy-discipline-lesson-plan-modal table tbody td.classroom").text(classroom);
    $("#copy-discipline-lesson-plan-modal table tbody td.discipline").text(discipline);
    $("#copy-discipline-lesson-plan-modal table tbody td.start_at").text(start_at);
    $("#copy-discipline-lesson-plan-modal table tbody td.end_at").text(end_at);
    $("#copy-discipline-lesson-plan-modal").modal('show');

    var params = {
      filter: {
        by_grade: grade_id,
        by_teacher_discipline: discipline_id,
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
