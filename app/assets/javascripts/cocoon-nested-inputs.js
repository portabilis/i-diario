$(function() {
  $('form').on('cocoon:before-insert', function(e, item) {
    item.fadeIn();
  }).on('cocoon:after-insert', function(e, item) {
    hideNoItemMessage();
    loadSelect2Inputs();
    loadDecimalMasks();
    loadDatepickers();
  }).on('cocoon:after-remove', function(e, item) {
    showNoItemMessage();
  });

  $("[data-nested-fields-container] a.add_fields").
    data("association-insertion-method", 'append').
    data("association-insertion-traversal", 'closest').
    data("association-insertion-node", '[data-nested-fields-container]');

  function hideNoItemMessage() {
    $('.no_item_found').hide();
  }

  function showNoItemMessage() {
    if (!$('.nested-fields').is(":visible")) {
      $('.no_item_found').show();
    }
  }

  function loadSelect2Inputs() {
    _.each($('.nested-fields input.select2'), function(element) {
      $(element).select2({
        formatResult: function(el) {
          return "<div class='select2-user-result'>" + el.name + "</div>";
        },
        formatSelection: function(el) {
          return el.name;
        },
        data: $(element).data('elements'),
        multiple: $(element).data('multiple')
      })
      .on('change', function(e) {
        var measuringUnit = getMeasuringUnitFromSelectedItem(e);

        $(e.target)
          .closest('[data-nested-fields]')
          .find('.measuring-unit')
          .html(measuringUnit);
      });
    });
  }

  function getMeasuringUnitFromSelectedItem(e) {
    return ($(e.target)
          .data('elements')
          .filter(function(element) {
            return element.id == e.val
          })[0]||{})['measuring_unit'];
  }

  function loadDecimalMasks() {
    $('.nested-fields input.decimal').inputmask('customDecimal');
  }

  function loadDatepickers() {
  	$('.datepicker:not([readonly]):not([disabled])').datepicker();
  }
});
