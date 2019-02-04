$(function () {
  'use strict';

  var selectedClassrooms;
  var record_date;
  var $disciplineContentRecord = $("#discipline_content_record_cloner_form_discipline_content_record_id");

  $('form').on('cocoon:before-insert', function(e, item) {
    item.fadeIn();
  }).on('cocoon:after-insert', function(e, item) {
    loadSelect2Inputs();
    setDefaultDates();
    generateItemUuid();
  });

  $(document).on('click', 'a.open_copy_modal', function(){
    var $row = $(this).closest('tr');
    var discipline_content_record_id = $(this).data('discipline-content-record-id');
    var discipline_id = $(this).data('discipline-id');
    var classroom_id = $(this).data('classroom-id');
    var grade_id = $(this).data('grade-id');

    $disciplineContentRecord.val(discipline_content_record_id);
    var classroom = $row.find(".classroom").text();
    var discipline = $row.find(".discipline").text();
    record_date = $row.find(".record_date").text();

    $("#copy-discipline-content-record-modal table tbody td.classroom").text(classroom);
    $("#copy-discipline-content-record-modal table tbody td.discipline").text(discipline);
    $("#copy-discipline-content-record-modal table tbody td.record_date").text(record_date);
    $('.remove_fields').click();
    $("#copy-discipline-content-record-modal").modal('show');

    var params = {
      filter: {
        by_grade: grade_id,
        by_teacher_discipline: discipline_id,
        different_than: classroom_id
      },
      find_by_current_year: true,
      find_by_current_teacher: true,
      include_unity: true
    };

    $.getJSON(Routes.classrooms_pt_br_path(params)).always(function (data) {
      selectedClassrooms = _.map(data, function(classroom) { return { id: classroom['id'], text: classroom['description']+' - '+classroom['unity']['name'] }; });
    });
  });

  function loadSelect2Inputs() {
    _.each($('.nested-fields input.select2'), function(element) {
      $(element).select2({ data: selectedClassrooms, multiple: false });
    });
    $(".nested-fields div[style*='display']").css("display", "");
  }

  function setDefaultDates() {
    _.each($(".nested-fields input[name*='record_date']"), function(element) {
      if ($(element).val() == "") {
        $(element).val(record_date);
      }
    });
  }

  function generateItemUuid() {
    _.each($('.has-no-id'), function(element) {
      var uuid = Math.random().toString(36).substring(2);
      $(element).addClass(uuid);
      $(element).removeClass("has-no-id");
      $(element).find("input[name*='uuid']").val(uuid);
    });
  }

});
