$(function() {
  $('input[id$=action]').change(function() {
    if($(this).val() == '3') {
      $(this).closest('tr').find('input[id$=exact_decimal_place]').removeAttr('readonly');
    } else {
      $(this).closest('tr').find('input[id$=exact_decimal_place]').attr('readonly', true).val('');
    }
  });

  $('input[id$=action]').trigger('change');
});
