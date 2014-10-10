$(function() {
  $("a.add_fields").
    data("association-insertion-method", 'append').
    data("association-insertion-traversal", 'closest').
    data("association-insertion-node", 'fieldset#items');

  $('form').on('cocoon:after-insert', function(e, item) {
    loadSelect2Inputs();
    loadDecimalMasks();
  })
  .on('cocoon:before-insert', function(e, item) {
    item.fadeIn();
  });

  function loadSelect2Inputs() {
    _.each($('.nested-fields input.select2'), function(element) {
      $(element).select2({
        formatResult: function(el) {
          return "<div class='select2-user-result'>" + el.name + "</div>";
        },
        formatSelection: function(el) {
          return el.name;
        },
        data: $(element).data('elements')
      })
      .on('change', function(e) {
        var measuringUnit = get***REMOVED***FromSelectedItem(e);

        $(e.target)
          .closest('[data-nested-fields]')
          .find('.measuring-unit')
          .html(measuringUnit);
      });
    });
  }

  function get***REMOVED***FromSelectedItem(e) {
    return $(e.target)
      .data('elements')
      .filter(function(element) {
        return element.id == e.val
      })[0].measuring_unit;
  }

  function loadDecimalMasks() {
    $('.nested-fields input.decimal').priceFormat({
      prefix: '',
      centsSeparator: ',',
      thousandsSeparator: '.'
    });
  }
});
