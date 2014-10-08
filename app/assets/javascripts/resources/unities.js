$(function() {
  $dataApiCode = $("[data-api-code]");

  $('#unity_unit_type').on("change", function(e) {
    if (e.val === 'cost_center') {
      $dataApiCode.hide();
      $dataApiCode.find('input').val('');
    } else {
      $dataApiCode.show();
    }
  });
});
