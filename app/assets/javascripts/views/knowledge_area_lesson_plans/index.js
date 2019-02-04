$(function () {
  'use strict';

  var selectedClassrooms;
  var start_at;
  var end_at;
  var $knowledgeAreaLessonPlan = $("#knowledge_area_lesson_plan_cloner_form_knowledge_area_lesson_plan_id");

  $('form').on('cocoon:before-insert', function(e, item) {
    item.fadeIn();
  }).on('cocoon:after-insert', function(e, item) {
    loadSelect2Inputs();
    setDefaultDates();
    generateItemUuid();
  });

  $(document).on('click', 'a.open_copy_modal', function(){
    var $row = $(this).closest('tr');
    var knowledge_area_lesson_plan_id = $(this).data('knowledge-area-lesson-plan-id');
    var classroom_id = $(this).data('classroom-id');
    var grade_id = $(this).data('grade-id');

    $knowledgeAreaLessonPlan.val(knowledge_area_lesson_plan_id);
    var classroom = $row.find(".classroom").text();
    var knowledge_area = $row.find(".knowledge_area").html();
    start_at = $row.find(".start_at").text();
    end_at = $row.find(".end_at").text();

    $("#copy-knowledge-area-lesson-plan-modal table tbody td.classroom").text(classroom);
    $("#copy-knowledge-area-lesson-plan-modal table tbody td.knowledge_area").html(knowledge_area);
    $("#copy-knowledge-area-lesson-plan-modal table tbody td.start_at").text(start_at);
    $("#copy-knowledge-area-lesson-plan-modal table tbody td.end_at").text(end_at);
    $('.remove_fields').click();
    $("#copy-knowledge-area-lesson-plan-modal").modal('show');

    var params = {
      filter: {
        by_grade: grade_id,
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
    _.each($(".nested-fields input[name*='start_at']"), function(element) {
      if ($(element).val() == "") {
        $(element).val(start_at);
      }
    });
    _.each($(".nested-fields input[name*='end_at']"), function(element) {
      if ($(element).val() == "") {
        $(element).val(end_at);
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
