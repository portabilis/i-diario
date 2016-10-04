$(function () {
  'use strict';

  var $classrooms = $("#knowledge_area_content_record_cloner_form_classroom_ids");
  var $knowledgeAreaContentRecord = $("#knowledge_area_content_record_cloner_form_knowledge_area_content_record_id");

  $(document).on('click', 'a.open_copy_modal', function(){

    var $row = $(this).closest('tr');
    var knowledge_area_content_record_id = $(this).data('knowledge-area-content-record-id');
    var classroom_id = $(this).data('classroom-id');
    var grade_id = $(this).data('grade-id');

    $classrooms.select2("val", "");
    $knowledgeAreaContentRecord.val(knowledge_area_content_record_id);
    $classrooms.closest(".control-group").removeClass("error");
    $classrooms.closest(".control-group").find("span.help-inline").remove();

    var classroom = $row.find(".classroom").text();
    var knowledge_area = $row.find(".knowledge_area").html();
    var record_date = $row.find(".record_date").text();

    $("#copy-knowledge-area-content-record-modal table tbody td.classroom").text(classroom);
    $("#copy-knowledge-area-content-record-modal table tbody td.knowledge_area").html(knowledge_area);
    $("#copy-knowledge-area-content-record-modal table tbody td.record_date").text(record_date);
    $("#copy-knowledge-area-content-record-modal").modal('show');

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
