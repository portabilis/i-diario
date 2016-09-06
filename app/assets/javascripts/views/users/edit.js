$(function(){
  "use strict";

  if ($('form.user-form').length > 0) {
    $("#user_cpf").inputmask("999.999.999-99");

    $('form').on("change", '.user-role', function (e) {
      var row = $(this).closest('.nested-fields'),
          $userUnity = row.find('.user-unity'),
          val = $(this).val();

      var mustShowUnity = _.find(window.roles, function (role) {
        return role['id'].toString() == val.toString() &&
          (role['access_level'] == 'unit' || role['access_level'] == 'teacher' || role['access_level'] == 'employee');
      });

      if (mustShowUnity) {
        $userUnity.removeClass("hidden");
      } else {
        $userUnity.find('input').select2('val', undefined);
        $userUnity.addClass("hidden");
      }
    });
  }

});
