$(document).ready(function(){
  _.each($('input.select2'), function(element) {
    $(element).select2({
      formatResult: function(el) {
        return "<div class='select2-user-result'>" + el.name + "</div>";
      },
      formatSelection: function(el) {
        return el.name;
      },
      data: $(element).data('elements'),
      multiple: $(element).data('multiple'),
      allowClear: !$(element).data('hide-empty-element')
    });

    if ($(element).data('multiple') && !$(element).data('without-json-parser')) {
      $(element).select2("val", JSON.parse($(element).val()));
    }
  });
});

$(function() {
  // Clear value when select empty element
  $('input.select2').on('change', function(element) {
    if (element.val === "empty") {
      $(element.target).select2("val", "");
    }
  });
})
