function createSelect2Ajax() {
  _.each($('input.select2_ajax, input[class^=select2_ajax]'), function(element) {
    $(element).select2({
      ajax: {
        url: function () {
          return $(element).data('url');
        },
        results: function (data, page) {
          return data; // Format: { id: 1, name: 'Name', text: 'Name' }
        },
        quietMillis: 500
      },
      initSelection: function(element, callback) {
        data = $(element).data('init-value');
        callback(data); // Format: { id: 1, name: 'Name', text: 'Name' }
      }
    });
  });
}

$(document).ready(function(){
  createSelect2Ajax()
});
