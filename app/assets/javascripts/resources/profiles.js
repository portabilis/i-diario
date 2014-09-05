$(document).ready(function(){
  if ($('body.profiles').length > 0) {

    $("input[type='checkbox']").on("change", function() {
      var permission = $(this).data('permission'),
          authenticityToken = $("meta[name='csrf-token']").attr("content"),
          value = $(this).prop('checked'),
          id = $(this).data('id'),
          params = { permission: permission, authenticity_token: authenticityToken, value: value }

      var notifyOptions = {
        autoHide : true,
        clickOverlay : false,
        MinWidth : 250,
        TimeShown : 1000,
        ShowTimeEffect : 200,
        HideTimeEffect : 200,
        LongTrip :20,
        HorizontalPosition : 'center',
        VerticalPosition : 'top',
        ShowOverlay : false,
      }

      var success = function(){
        jNotify(
          'Perfil salvo com sucesso.',
          notifyOptions
        );
      }

      var error = function(){
        jError(
          'Não foi possível salvar o perfil.',
          notifyOptions
        );
      }

      $.ajax({
        type: "PUT",
        url: '/profiles/' + id,
        data: params,
        success: success,
        error: error
      });
    });
  }
});
