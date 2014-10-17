$(function() {
  var $dataApiCode = $("[data-unity-api-code]"),
      $unitType = $("#unity_unit_type");

  toggleApiCode($unitType.val() !== 'cost_center');

  $('#unity_unit_type').on("change", function(e) {
    toggleApiCode(e.val !== 'cost_center');
  });

  function toggleApiCode(show) {
    if (show) {
      $dataApiCode.show();
    } else {
      $dataApiCode.hide();
      $dataApiCode.find('input').val('');
    }
  }
});
