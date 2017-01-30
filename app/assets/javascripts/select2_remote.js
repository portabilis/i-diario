$(document).ready(function(){
  _.each($('input.select2_remote, input[class^=select2_remote]'), function(element) {
    $(element).select2({
      ajax: {
        url: $(element).data('data-url'),
        delay: 250,
        dataType: "json",
        type: "GET",
        data: function (term) {
          return {
            description: term
          };
        },
        results: function (data) {
          var myResults = [];
          $.each(data, function (index, item) {
            myResults.push({
              id: item.id,
              description: item.description
            });
          });

          return {
            results: myResults
          };
        },
        cache: true
      },
      formatResult: function(el) {
        return "<option>" + el.description + "</option>";
      },
      formatSelection: function(el) {
        return el.description;
      },
      minimumInputLength: 3,
      initSelection: function(element, callback) {
        data = $(element).data('init-value');
        callback(data);
      },
      multiple: $(element).data('multiple'),
      allowClear: !$(element).data('hide-empty-element')
    });

    if ($(element).data('multiple') && !$(element).data('without-json-parser') && !_.isEmpty($(element).val())){
      $(element).select2("val", JSON.parse($(element).val()));
    }
  });
});

$(function() {
  // Clear value when select empty element
  $('input.select2_remote, input[class^=select2_remote]').on('change', function(element) {
    if (element.val === "empty") {
      $(element.target).select2("val", "");
    }
  });
})
