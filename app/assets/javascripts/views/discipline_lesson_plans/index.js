$(function () {
  'use strict';

  $('a.open_copy_modal').on('click', function(){

    var $row = $(this).closest('tr');

    var classroom = $row.find(".classroom").text();
    var discipline = $row.find(".discipline").text();
    var start_at = $row.find(".start_at").text();
    var end_at = $row.find(".end_at").text();

    $("#copy-discipline-lesson-plan-modal table tbody td.classroom").text(classroom);
    $("#copy-discipline-lesson-plan-modal table tbody td.discipline").text(discipline);
    $("#copy-discipline-lesson-plan-modal table tbody td.start_at").text(start_at);
    $("#copy-discipline-lesson-plan-modal table tbody td.end_at").text(end_at);
    $("#copy-discipline-lesson-plan-modal").modal('show');

  });
});
