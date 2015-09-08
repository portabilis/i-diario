$(function() {
  $('#select-all-unities').on('click', function () {
    $('input[type=checkbox]').prop('checked', $(this).prop('checked'))
  });
});