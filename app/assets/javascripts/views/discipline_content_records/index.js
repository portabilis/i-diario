$(function () {
  'use strict';

  var $classrooms = $("#discipline_content_record_cloner_form_classroom_ids");
  var $disciplineContentRecord = $("#discipline_content_record_cloner_form_discipline_content_record_id");

  $(document).on('click', 'a.open_copy_modal', function(){

    var $row = $(this).closest('tr');
    var discipline_content_record_id = $(this).data('discipline-content-record-id');
    var discipline_id = $(this).data('discipline-id');
    var classroom_id = $(this).data('classroom-id');
    var grade_id = $(this).data('grade-id');

    $classrooms.select2("val", "");
    $disciplineContentRecord.val(discipline_content_record_id);
    $classrooms.closest(".control-group").removeClass("error");
    $classrooms.closest(".control-group").find("span.help-inline").remove();

    var classroom = $row.find(".classroom").text();
    var discipline = $row.find(".discipline").text();
    var record_date = $row.find(".record_date").text();

    $("#copy-discipline-content-record-modal table tbody td.classroom").text(classroom);
    $("#copy-discipline-content-record-modal table tbody td.discipline").text(discipline);
    $("#copy-discipline-content-record-modal table tbody td.record_date").text(record_date);
    $("#copy-discipline-content-record-modal").modal('show');

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
