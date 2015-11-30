$(document).ready(function(){
  if ($('form.user-form').length > 0) {
    $("#user_cpf").inputmask("999.999.999-99");

    $('form').on("change", '.user-role', function (e) {
      var row = $(this).closest('.nested-fields'),
          $userUnity = row.find('.user-unity'),
          val = $(this).val();

      var isParentOrStudent = _.find(window.roles, function (role) {
        return role['id'].toString() == val.toString() && (role['kind'] == 'student' || role['kind'] == 'parent');
      });

      if (!!isParentOrStudent) {
        $userUnity.addClass("hidden");
        $userUnity.find('input').select2('val', '');
      } else {
        $userUnity.removeClass("hidden");
      }
    });
  }
});
