$(function() {
  var $returnReasonContainer = $("[data-material-exit-return-reason]"),
      $requestAuthorizationContainer = $("[data-material-exit-request-authorization]"),
      $destinationUnityContainer = $("[data-material-exit-destination-unity]"),
      $materialItemsContainer = $("[data-material-exit-items-container]"),
      $returnReason = $("#material_exit_return_reason"),
      $kind = $("#material_exit_kind"),
      $requestAuthorization = $("#material_exit_material_request_authorization_id"),
      $destinationUnity = $("#material_exit_destination_unity_id"),
      itemTemplate = $("#material_exit_items a.add_fields").attr("data-association-insertion-template");
      flashMessages = new FlashMessages(),

  toggleReturnReason($kind.val() === 'return');
  toggleRequestAuthorization($kind.val() === 'transfer');
  toggleDestinationUnity($kind.val() !== 'consumption');

  $kind.on('change', function(e) {
    toggleReturnReason(e.val === 'return');
    toggleRequestAuthorization(e.val === 'transfer');
    toggleDestinationUnity(e.val !== 'consumption');
  });

  $requestAuthorization.on('change', function(e) {
    fetchAuthorizationItems(e.val);
  });

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

    $materialItemsContainer.hide();
    $materialItemsContainer.find("a.remove_fields").trigger("click");

    _.each(items, function(item) {
      item.quantity = parseFloat(item.quantity).toFixed(2);
      output.push(updateTemplate(item));
    });

    $materialItemsContainer.append(output);
    $('form').trigger('cocoon:after-insert');
    $materialItemsContainer.show();
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
      $returnReasonContainer.show();
    } else {
      $returnReasonContainer.hide();
      $returnReason.val('');
    }
  }

  function toggleRequestAuthorization(show) {
    if (show) {
      $requestAuthorizationContainer.show();
    } else {
      $requestAuthorizationContainer.hide();
      $requestAuthorization.select2('val', '');
    }
  }

  function toggleDestinationUnity(show) {
    if (show) {
      $destinationUnityContainer.show();
    } else {
      $destinationUnityContainer.hide();
      $destinationUnity.select2('val', '');
    }
  }
});
