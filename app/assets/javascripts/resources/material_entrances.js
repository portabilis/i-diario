$(function() {
  var $supplier = $("[data-material-entrance-supplier]"),
      $materialExitFields = $("[data-material-entrance-material-exit]"),
      $materialItems = $("#material-entrance-items"),
      $kind = $("#material_entrance_kind"),
      $materialExit = $("#material_entrance_material_exit_id"),
      itemTemplate = $("#material_entrance_items a.add_fields").attr("data-association-insertion-template"),
      flashMessages = new FlashMessages();

  toggle***REMOVED***($kind.val() === 'supplier');
  toggle***REMOVED***($kind.val() === 'return' || $kind.val() === 'transfer');

  $kind.on('change', function(e) {
    toggle***REMOVED***(e.val === 'supplier');
    toggle***REMOVED***(e.val === 'return' || e.val === 'transfer');
  });

  $materialExit.on('change', function(e) {
    fetchExitItems(e.val);
  });

  function fetchExitItems(exitId) {
    $.ajax({
      url: '/saidas-de-materiais/' + exitId + '/items-de-saidas-de-materiais.json',
      success: renderExitItems,
      error: handleError
    });
  }

  function renderExitItems(items) {
    var output = [];

    $materialItems.hide();
    $materialItems.find("a.remove_fields").trigger("click");

    _.each(items, function(item) {
      item.quantity = parseFloat(item.quantity).toFixed(2);
      output.push(updateTemplate(item));
    });

    $materialItems.append(output);
    $('form').trigger('cocoon:after-insert');
    $materialItems.show();
  }

  function updateTemplate(item) {
    var output = [];

    output = $(itemTemplate.replace(/new_items/g, new Date().getTime()));

    output.find("[id$=quantity]").val(item.quantity);
    output.find("[id$=material_id]").val(item.material.id);
    output.find("span.measuring-unit").html(item.material.measuring_unit);

    return output;
  }

  function handleError() {
    flashMessages.error('Problemas ao buscar items da saída.');
  }

  function toggle***REMOVED***(show) {
    if (show) {
      $supplier.show();
    } else {
      $supplier.hide().find("input").val("");
      $supplier.find("input.select2").select2("val", "");
    }
  }

  function toggle***REMOVED***(show) {
    if (show) {
      $materialExitFields.show();
    } else {
      $materialExitFields.hide().
        find("input.select2").select2("val", "");
    }
  }
});
