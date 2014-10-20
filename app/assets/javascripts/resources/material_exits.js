$(function() {
  var $returnReasonDiv = $("[data-material-exit-return-reason]"),
      $returnReason = $("#material_exit_return_reason"),
      $materialExitKind = $("#material_exit_kind");

  toggleReturnReason($materialExitKind.val() === 'return');

  $materialExitKind.on('change', function(e) {
    toggleReturnReason(e.val === 'return');
  });

  $("fieldset#material_exit_items a.add_fields").
    data("association-insertion-method", 'append').
    data("association-insertion-traversal", 'closest').
    data("association-insertion-node", 'fieldset#material_exit_items');

  function toggleReturnReason(show) {
    if (show) {
      $returnReasonDiv.show();
    } else {
      $returnReasonDiv.hide();
      $returnReason.val('');
    }
  }
});
