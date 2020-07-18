$(function() {
  'use strict';

  var toggleUserReceiveNewsOptions = function(){
    if($("#user_receive_news").prop("checked")){
      $(".receive_news_options").show();
    }else{
      $(".receive_news_options").hide();
    }
  }
  $("#user_receive_news").on("change", toggleUserReceiveNewsOptions);
  toggleUserReceiveNewsOptions();

  window.addEventListener('DOMContentLoaded', function () {
    var avatar = $('#profile-picture-prev')[0];
    var menu_avatar = $('#menu_avatar')[0];
    var image = $('#profile-image')[0];
    var input = $('#profile-picture-input')[0];

    var $alert = $('.profile-picture-alert');
    var $modal = $('#profile-picture-modal');
    var cropper;
    var fileName;

    $('#profile-picture-input').on('change', function (e) {
      var files = e.target.files;
      var done = function (url) {
        input.value = '';
        image.src = url;
        $alert.hide();
        $modal.modal('show');
      };
      var reader;
      var file;
      var url;

      if (files && files.length > 0) {
        file = files[0];
        fileName = file.name;

        if (URL) {
          done(URL.createObjectURL(file));
        } else if (FileReader) {
          reader = new FileReader();
          reader.onload = function (e) {
            done(reader.result);
          };
          reader.readAsDataURL(file);
        }
      }
    });

    $modal.on('shown.bs.modal', function () {
      cropper = new Cropper(image, {
        aspectRatio: 1,
        viewMode: 3,
      });
    }).on('hidden.bs.modal', function () {
      cropper.destroy();
      cropper = null;
    });

    $('#crop-profile-picture').on('click', function () {
      var initialAvatarURL;
      var canvas;

      $modal.modal('hide');

      if (cropper) {
        canvas = cropper.getCroppedCanvas({
          width: 160,
          height: 160,
        });

        if (canvas) {
          initialAvatarURL = avatar.src;
          avatar.src = canvas.toDataURL();
          menu_avatar.src = canvas.toDataURL();

          $alert.removeClass('alert-success alert-warning');
          canvas.toBlob(function (blob) {
            var formData = new FormData();
            var userId = $('#user_id').val();

            formData.append('profile_picture', blob, fileName);
            formData.append('locale', 'pt-BR');
            formData.append('id', userId);

            $.ajax({
                url: Routes.profile_picture_users_pt_br_path(),
                method: 'POST',
                data: formData,
                processData: false,
                contentType: false,
                dataType: 'json',
              success: function (data) {
                $('#profile-picture-alert-span').text('Foto de perfil atualizada com sucesso');
                $alert.show().addClass('alert-success');
                avatar.src = data.url
                menu_avatar.src = data.url
              },
              error: function (data) {
                avatar.src = initialAvatarURL;
                menu_avatar.src = initialAvatarURL;
                $('#profile-picture-alert-span').text(data.responseJSON.users[0]);
                $alert.show().addClass('alert-warning');
              },
            })
          });
        } else {
          $('#profile-picture-alert-span').text('Formato desconhecido');
          $alert.show().addClass('alert-warning');
        }
      }
    });
  });
});
