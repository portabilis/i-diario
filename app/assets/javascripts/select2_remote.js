function createAllSelect2Remote() {
  createAllSelect2Remote(false);
}

function createAllSelect2Remote(all) {
  createSelect2Remote(all, '', '');
}

function createSelect2Remote(all, items, url) {
  _.each($((items != '') ? items : 'input.select2_remote, input[class^=select2_remote]'), function(element) {
    if (all || (!all && element.value == "")) {
      $(element).select2({
        ajax: {
          url: (url != '') ? url : $(element).data('data-url'),
          quietMillis: 500,
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
    }
  });

  // Clear value when select empty element
  $('input.select2_remote, input[class^=select2_remote]').on('change', function(element) {
    if (element.val === "empty") {
      $(element.target).select2("val", "");
    }
  });
}

$(document).ready(function(){
  createAllSelect2Remote(true);
});
