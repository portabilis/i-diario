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
      multiple: $(element).data('multiple')
    });

    if ($(element).data('multiple')) {
      $(element).select2("val", JSON.parse($(element).val()));
    }
  });
});
