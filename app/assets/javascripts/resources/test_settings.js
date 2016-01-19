$(function() {
  var $itemSettingTests = $("#item_setting_tests"),
      $fixTests = $("#test_setting_fix_tests"),
      $numberOfDecimalPlaces = $('#test_setting_number_of_decimal_places');

  toggleItemSettingsTests($fixTests.prop('checked'));

  $fixTests.on('change', function() {
    toggleItemSettingsTests($fixTests.prop('checked'));
  });

  function toggleItemSettingsTests(show) {
    if (show) {
      $itemSettingTests.show();
    } else {
      $itemSettingTests.hide();
    }
  }

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
    var $test_setting_school_term_input = $('#test_setting_school_term');

    if ($('#test_setting_exam_setting_type').select2('val') == 'by_school_term') {
      $test_setting_school_term_div.show();
    } else {
      $test_setting_school_term_div.hide();
      $test_setting_school_term_input.select2('val', '');
    }
  }

  updateTestSettingSchoolTermInput();
});
