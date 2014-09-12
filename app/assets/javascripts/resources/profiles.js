$(document).ready(function(){
  if ($('body.profiles').length > 0) {

    $("input[type='checkbox']").on("change", function() {
      var permission = $(this).data('permission'),
          authenticityToken = $("meta[name='csrf-token']").attr("content"),
          value = $(this).prop('checked'),
          id = $(this).data('id'),
          params = { permission: permission, authenticity_token: authenticityToken, value: value }

      var flashMessages = new FlashMessages();

      var success = function(){
        flashMessages.success('Perfil salvo com sucesso.');
      }

      var error = function(){
        flashMessages.error('Não foi possível salvar o perfil.');
      }

      $.ajax({
        type: "PUT",
        url: '/perfis/' + id,
        data: params,
        success: success,
        error: error
      });
    });
  }
});
