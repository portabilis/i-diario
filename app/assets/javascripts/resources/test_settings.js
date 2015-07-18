$(function() {
  var $itemSettingTests = $("#item_setting_tests"),
      $fixTests = $("#test_setting_fix_tests");

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

  function updatePriceFormat(centsLimit) {
    $('input.string[id^=test_setting_tests_attributes][id*=_weight]').priceFormat({
      prefix: '',
      centsSeparator: ',',
      thousandsSeparator: '.',
      centsLimit: parseInt($('#test_setting_number_of_decimal_places').val()) || 0
    });
  }
});
