$(function() {
  $('#select-all-unities').on('click', function () {
    $('input[type=checkbox]').prop('checked', $(this).prop('checked'))
  });

  $('.simple_form.synchronize input[type=checkbox]').on('change', function() {
    refreshSynchronizeSubmitButton();
  });

  var refreshSynchronizeSubmitButton = function() {
    if ($('.simple_form.synchronize tbody > tr > td > label > input:checkbox:checked').length > 0) {
      $('.simple_form.synchronize button[type=submit]').removeClass('disabled');
    } else {
      $('.simple_form.synchronize button[type=submit]').addClass('disabled');
    }
  }

  refreshSynchronizeSubmitButton();
});