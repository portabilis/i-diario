$(function () {

  var $unity = $("#avaliation_multiple_creator_form_unity_id");
  var $discipline = $("#avaliation_multiple_creator_form_discipline_id");

  window.testSettingTests = []
  var fetchTestSettingTests = function (params, callback) {
    if (_.isEmpty(window.testSettingTests)) {
      $.getJSON('/test_setting_tests?' + $.param(params)).always(function (data) {
        window.testSettingTests = data.test_setting_tests;
        callback(window.testSettingTests);
      });
    } else {
      callback(window.testSettingTests);
    }
  };

  var updateFieldsBasedOnTestSetting = function() {
    $.getJSON('/configuracoes-de-avaliacoes-numericas/' + $('#avaliation_multiple_creator_form_test_setting_id').select2('val')).always(function(data) {
      if ($.inArray(data.test_setting.exam_setting_type, ['general', 'general_by_school' ]) != -1){
        $('.avaliation_multiple_creator_form_test_setting_id').hide();
      }

      switch (data.test_setting.average_calculation_type) {
        case "sum":
          $('.avaliation_multiple_creator_form_test_setting_test_id').show();
          $('.avaliation_multiple_creator_form_description').hide();
          $('.avaliation_multiple_creator_form_weight').hide();
          break;

        case "arithmetic":
          $('.avaliation_multiple_creator_form_test_setting_test_id').hide();
          $('.avaliation_multiple_creator_form_description').show();
          $('.avaliation_multiple_creator_form_weight').hide();
          break;

        case "arithmetic_and_sum":
          $('.avaliation_multiple_creator_form_description').show();
          $('.avaliation_multiple_creator_form_weight').show();
          $('.avaliation_multiple_creator_form_test_setting_test_id').hide();
          break;

        default:
          console.log("Behavior not yet implemented for this average calculation type: " + data.test_setting.average_calculation_type);
      }

      $weight_input.attr('data-inputmask', "'digits': " + (parseInt(data['test_setting']['number_of_decimal_places']) || 0));
      $weight_input.inputmask('customDecimal');
    });

    var params = { test_setting_id: $('#avaliation_multiple_creator_form_test_setting_id').select2('val') };
    window.testSettingTests = [];
    if (_.isEmpty($('#avaliation_multiple_creator_form_test_setting_id').select2('val'))) {
      $('#avaliation_multiple_creator_form_test_setting_test_id').val('');
      $('#avaliation_multiple_creator_form_test_setting_test_id').select2({ data: [] });
    } else {
      fetchTestSettingTests(params, function (testSettingTests) {
        var selectedTestSettingTests = _.map(testSettingTests, function (testSettingTest) {
          return { id: testSettingTest['id'], text: testSettingTest['description'] };
        });

        $('#avaliation_multiple_creator_form_test_setting_test_id').select2({
          data: selectedTestSettingTests
        });
      });
    }
  }

  $('#avaliation_multiple_creator_form_test_setting_id').on('change', function (e) {
    updateFieldsBasedOnTestSetting();
  });

  var $test_setting_input = $('#avaliation_multiple_creator_form_test_setting_test_id');
  $test_setting_input.on('change', function(e) {
    updateFieldsBaseOnTestSettingTest();
  });

  var $description_and_weight_div = $('#show_when_allow_break_up');
  var $description_input = $('#avaliation_multiple_creator_form_description');
  var $weight_input = $('#avaliation_multiple_creator_form_weight');

  var updateFieldsBaseOnTestSettingTest = function() {
    if (_.isEmpty($test_setting_input.select2('val')) || $test_setting_input.select2('val') == 'empty') {
      $('.avaliation_multiple_creator_form_description').hide();
      $('.avaliation_multiple_creator_form_weight').hide();

      return;
    }

    $.getJSON('/test_setting_tests/' + $test_setting_input.select2('val')).always(function(data) {
      if (data.allow_break_up) {
        $('.avaliation_multiple_creator_form_description').show();
        $('.avaliation_multiple_creator_form_weight').show();
      } else {
        $('.avaliation_multiple_creator_form_description').hide();
        $('.avaliation_multiple_creator_form_weight').hide();
      }
    });
  }

  var classes_data = function(){
    data = [];
    for (var i = 1; i <= window.number_of_classes; i++) {
      data.push({
        id: i,
        name: i.toString(),
        text: i.toString()
      });
    }
    return data;
  }

  $discipline.on("change", function(){
    $("#avaliations .nested-fields").remove();
    $("#avaliations tr td").show();

    if(!$discipline.val().length){
      return false;
    }

    var params = {
      filter: {
        by_unity: $unity.val(),
        by_teacher_discipline: $discipline.val()
      },
      find_by_current_teacher: true,
      find_by_current_year: true
    };

    $.getJSON(Routes.classroom_grades_classrooms_pt_br_path(params)).always(function (data) {

      var classrooms = data['classroom_grades'][0];
      var grades = data['classroom_grades'][1];

      if (classrooms.length) {
        $("#avaliations tr td").hide();
      }

      $.each(classrooms, function(i, classroom){
        var element_id = new Date().getTime() + i;

        var html = JST['templates/avaliations/avaliation_fields']({
          classroom_id: classroom.id,
          classroom_name: classroom.description,
          grade_ids: grades.map(grade => grade.id),
          grade_name: grades.map(grade => grade.description),
          element_id: element_id,
        });

        $('#avaliations').append(html);
      });
      $('.datepicker:not([readonly]):not([disabled])').datepicker();

      $('input[data-mask]').on('focus', function () {
        var input = $(this);

        input.inputmask(input.attr('data-mask'));
      });
    });
  });

  $("#select-all").on('change', function(){
    $(this).closest("table").find("tbody input[type=checkbox]").prop("checked", $(this).prop("checked")).trigger("change");
  });

  function initFields() {
    if (!!document.getElementById('avaliation_multiple_creator_form_test_setting_id')) {
      updateFieldsBasedOnTestSetting();
    }

    if (!!document.getElementById('avaliation_multiple_creator_form_weight')) {
      updateFieldsBaseOnTestSettingTest();
    }
  }

  $(document).ready(function(){
    initFields();
  });
});
