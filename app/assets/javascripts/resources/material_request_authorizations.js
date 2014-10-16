$(function() {
  var $reason = $("#material_request_authorization_reason"),
      $status = $("#material_request_authorization_status"),
      $materialRequest = $("#material_request_authorization_material_request_id"),
      $reasonDiv = $("[data-reason]"),
      $items = $("#material_request_authorization_items"),
      itemTemplate = HandlebarsTemplates["***REMOVED***/item"],
      flashMessages = new FlashMessages();

  toggleReason($status.val() !== 'granted');
  toggleItems($status.val() === 'partially_granted');

  $status.on('change', function(e) {
    toggleReason(e.val !== 'granted');
    toggleItems(e.val === 'partially_granted');

    if (e.val === 'partially_granted' && $materialRequest.val() !== '') {
      fetch***REMOVED***RequestItems($materialRequest.val());
    }
  });

  $materialRequest.on('change', function(e) {
    fetch***REMOVED***RequestItems(e.val);
  });

  function fetch***REMOVED***RequestItems(materialId) {
    $.ajax({
      url: '/***REMOVED***/' + materialId + '/material_request_items.json',
      success: renderItems,
      error: handleError
    });
  }

  function renderItems(items) {
    var output = [];

    _.each(items, function(item) {
      item.quantity = parseFloat(item.quantity).toFixed(2);
      output.push(itemTemplate(item));
    });

    $("fieldset#items div").html(output);
    $('input.decimal').priceFormat({ prefix: '', centsSeparator: ',', thousandsSeparator: '.' });
  }

  function handleError() {
    flashMessages.error('Problemas ao buscar items da requisição.');
  }

  function toggleReason(show) {
    if (show) {
      $reasonDiv.show();
    } else {
      $reasonDiv.hide();
      $reason.val('');
    }
  }

  function toggleItems(show) {
    if (show) {
      $items.show();
    } else {
      $items.hide();
    }
  }
});
