$(function() {
  var $itemSettingTests = $("#item_setting_tests"),
      $averageCalculationType = $("#test_setting_average_calculation_type"),
      $numberOfDecimalPlaces = $('#test_setting_number_of_decimal_places');

  toggleItemSettingsTests($averageCalculationType.select2("val"));

  $averageCalculationType.on('change', function() {
    toggleItemSettingsTests($averageCalculationType.select2("val"));
    toggleAverageCalculationInfo($averageCalculationType.select2("val"));
    toggleAverageSumWeightSelection($averageCalculationType.select2("val"));
  });

  function toggleItemSettingsTests(averageCalculationType) {
    if (averageCalculationType === "sum") {
      $itemSettingTests.show();
    } else {
      $itemSettingTests.hide();
    }
  }

  function toggleAverageSumWeightSelection(averageCalculationType) {
    var $divisionWeightCheckContainer = $('#division-weight-check-container');

    if (averageCalculationType === "sum" && $('#test_setting_exam_setting_type').select2('val') == 'general_by_school') {
      $divisionWeightCheckContainer.show();
    } else {
      $divisionWeightCheckContainer.hide();
    }
  }

  toggleAverageSumWeightSelection($averageCalculationType.select2("val"));

  updatePriceFormat();

  $('#test_setting_number_of_decimal_places').on('change', function() {
    updatePriceFormat();
  });

  function updatePriceFormat() {
    $('input.string[id^=test_setting_tests_attributes][id*=_weight]').attr('data-inputmask', "'digits': " + ($numberOfDecimalPlaces.val() || 0));

    $('input.string[id^=test_setting_tests_attributes][id*=_weight]').inputmask('customDecimal');
  }

  $('form').on('cocoon:after-insert', function(e, item) {
    updatePriceFormat();
  })

  $('#test_setting_exam_setting_type').on('change', function(e) {
    updateTestSettingSchoolTermInput();
  });

  var updateTestSettingSchoolTermInput = function() {
    var $test_setting_school_term_div = $('#test_setting_school_term_div');
    var $test_setting_school_term_input = $('#test_setting_school_term_type_step_id');
    var $test_setting_unities_div = $('#test_setting_unities_div');
    var $test_setting_unities_input = $('#test_setting_unities');
    var $test_setting_grades_div = $('#test_setting_grades_div');
    var $test_setting_grades_input = $('#test_setting_grades');
    var $divisionWeightCheckContainer = $('#division-weight-check-container');

    if ($('#test_setting_exam_setting_type').select2('val') == 'by_school_term') {
      $test_setting_unities_div.hide();
      $test_setting_unities_input.select2('val', '');
      $test_setting_grades_div.hide();
      $test_setting_grades_input.select2('val', '');
      $divisionWeightCheckContainer.hide();

      $test_setting_school_term_div.show();
    } else if ($('#test_setting_exam_setting_type').select2('val') == 'general_by_school') {
      $test_setting_school_term_div.hide();
      $test_setting_school_term_input.select2('val', '');

      $test_setting_unities_div.show();
      $test_setting_grades_div.show();

      if ($averageCalculationType.select2('val') === "sum") {
        $divisionWeightCheckContainer.show();
      }
    } else {
      $test_setting_unities_div.hide();
      $test_setting_unities_input.select2('val', '');
      $test_setting_grades_div.hide();
      $test_setting_grades_input.select2('val', '');
      $test_setting_school_term_div.hide();
      $test_setting_school_term_input.select2('val', '');
      $divisionWeightCheckContainer.hide();
    }
  }

  updateTestSettingSchoolTermInput();
  toggleAverageCalculationInfo($averageCalculationType.select2("val"));

  function toggleAverageCalculationInfo(average_calculation_type){
    hideAllAverageCalculationInfo();
    var averageCalculationTypeElementId = average_calculation_type + '-calculation-info';
    $averageCalculationTypeElement = $('#' + averageCalculationTypeElementId);
    $averageCalculationTypeElement.removeClass('hidden');
  }

  function hideAllAverageCalculationInfo(){
    $(".calculation-info").each(function(){
      $(this).addClass('hidden');
    });
  }

  $('#test_setting_unities').on('change.select2', function(e) {
    var $test_setting_unities = $('#test_setting_unities').val();

    if (!_.isEmpty($test_setting_unities)) {
      $.ajax({
        url: Routes.grades_by_unities_test_settings_pt_br_path({
            unities: $test_setting_unities,
            format: 'json'
        }),
        success: handleFetchGradesSuccess,
        error: handleFetchGradesError
      });
    } else {
      $('#test_setting_grades').select2('val', '');
      $('#test_setting_grades').select2({ data: [], multiple: true });
    }
  });

  function handleFetchGradesSuccess(grades) {
    var grades = _.map(grades.test_settings, function(grade) {
      return grade['table'];
    });

    grades_ids = _.map(grades, function(grade) {
      return grade.id;
    });

    $('#grades_list').val(grades_ids);
    $('#test_setting_grades').select2({ data: grades, multiple: true });
  }

  function handleFetchGradesError(grades) {
    console.log(grades)
  }

  $('#division-weight-check').on('click', function (e) {
    if(this.checked) {
     $('#division-weight-input').removeClass('hidden');
    } else {
      $('#division-weight-input').addClass('hidden');
    }
  });

  if ($('#test_setting_default_division_weight').val() > 1 ||
      ($("#test_setting_average_calculation_type").select2('val') == 'sum' &&
       $('#division-weight-check').is(':checked'))) {
    $('#division-weight-input').removeClass('hidden');
  }

  $('#test-settings-form-submit').on('click', function (e) {
    if ($("#test_setting_average_calculation_type").select2('val') == 'sum' &&
        !$('#division-weight-check').is(':checked')) {
      $('#test_setting_default_division_weight').val(1);
    }
  });

  var $selectAllUnities = $('#select-all-unities'),
      $deselectAllUnities = $('#deselect-all-unities'),
      $selectAllGrades = $('#select-all-grades'),
      $deselectAllGrades = $('#deselect-all-grades');

  $selectAllUnities.on('click', function(){
    allUnities = _.map($.parseJSON($("#test_setting_unities").attr('data-elements')), function(unitiy) {
      return unitiy.id;
    });

    allUnities.shift();
    $('#test_setting_unities').val(allUnities);
    $('#test_setting_unities').trigger("change.select2");

    $selectAllUnities.hide();
    $deselectAllUnities.show();
    $selectAllGrades.show();
  });

  $deselectAllUnities.on('click', function(){

    $('#test_setting_unities').val("");
    $('#test_setting_unities').trigger("change.select2");
    $('#test_setting_unities').val("");
    $('#test_setting_unities').trigger("change.select2");

    $selectAllUnities.show();
    $deselectAllUnities.hide();
    $selectAllGrades.hide();
    $deselectAllGrades.hide();
  });

  $selectAllGrades.on('click', function(){
    $('#test_setting_grades').val($('#grades_list').val());
    $('#test_setting_grades').trigger("change.select2");

    $selectAllGrades.hide();
    $deselectAllGrades.show();
  });

  $deselectAllGrades.on('click', function(){
    $('#test_setting_grades').val("");
    $('#test_setting_grades').trigger("change.select2");

    $selectAllGrades.show();
    $deselectAllGrades.hide();
  });
});
