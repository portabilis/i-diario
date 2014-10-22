$(function() {
  var $returnReasonDiv = $("[data-material-exit-return-reason]"),
      $requestAuthorizationDiv = $("[data-material-exit-request-authorization]"),
      $destinationUnityDiv = $("[data-material-exit-destination-unity]"),
      $returnReason = $("#material_exit_return_reason"),
      $materialExitKind = $("#material_exit_kind"),
      $requestAuthorization = $("#material_exit_material_request_authorization_id"),
      $destinationUnity = $("#material_exit_destination_unity_id"),
      $materialItems = $("fieldset#material_exit_items div"),
      flashMessages = new FlashMessages(),
      itemTemplate = $("#material_exit_items a.add_fields").attr("data-association-insertion-template");

  toggleReturnReason($materialExitKind.val() === 'return');
  toggleRequestAuthorization($materialExitKind.val() === 'transfer');
  toggleDestinationUnity($materialExitKind.val() !== 'consumption');

  $materialExitKind.on('change', function(e) {
    toggleReturnReason(e.val === 'return');
    toggleRequestAuthorization(e.val === 'transfer');
    toggleDestinationUnity(e.val !== 'consumption');
  });

  $requestAuthorization.on('change', function(e) {
    fetchAuthorizationItems(e.val);
  });

  $("fieldset#material_exit_items a.add_fields").
    data("association-insertion-method", 'append').
    data("association-insertion-traversal", 'closest').
    data("association-insertion-node", 'fieldset#material_exit_items');

  function fetchAuthorizationItems(authorizationId) {
    $.ajax({
      url: '/autorizacoes-de-requisicoes-de-materiais/' + authorizationId +
        '/items-de-autorizacoes-de-requisicoes-de-materiais.json',
      success: renderAuthorizationItems,
      error: handleError
    });
  }

  function renderAuthorizationItems(items) {
    var output = [];

    $materialItems.html('');

    _.each(items, function(item) {
      item.quantity = parseFloat(item.quantity).toFixed(2);
      output.push(updateTemplate(item));
    });

    $materialItems.html(output);
    $('form').trigger('cocoon:after-insert');
  }

  function handleError() {
    flashMessages.error('Problemas ao buscar items da autorização.');
  }

  function updateTemplate(item) {
    var output = $(itemTemplate.replace(/new_items/g, new Date().getTime()));

    output.find("[id$=quantity]").val(item.quantity);
    output.find("[id$=material_id]").val(item.material.id);
    output.find("span.measuring-unit").html(item.material.measuring_unit);

    return output;
  }

  function toggleReturnReason(show) {
    if (show) {
      $returnReasonDiv.show();
    } else {
      $returnReasonDiv.hide();
      $returnReason.val('');
    }
  }

  function toggleRequestAuthorization(show) {
    if (show) {
      $requestAuthorizationDiv.show();
    } else {
      $requestAuthorizationDiv.hide();
      $requestAuthorization.select2('val', '');
    }
  }

  function toggleDestinationUnity(show) {
    if (show) {
      $destinationUnityDiv.show();
    } else {
      $destinationUnityDiv.hide();
      $destinationUnity.select2('val', '');
    }
  }
});
