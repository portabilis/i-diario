$(document).ready(function(){
  if ($('form#edit_user').length > 0) {
    $("#user_phone").inputmask("(99) 9999-9999");
    $("#user_cpf").inputmask("999.999.999-99");
  }
});
