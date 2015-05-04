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
});
