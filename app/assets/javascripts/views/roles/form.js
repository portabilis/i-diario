$(function() {
  $('form').on('cocoon:after-insert', function(){
    var $lastTr = $('tbody#user-roles tr:last');
    var idSplitted = $lastTr.find('[id*="_id"]').last().attr('id').split('_');
    var uniqueId = idSplitted[idSplitted.length-2];

    $('tbody#user-roles tr:last').find('[name*="cocoonReplaceUniqueId"]').each(function(){
      $(this).attr('name', $(this).attr('name').replace('cocoonReplaceUniqueId', uniqueId));
    });

    $('tbody#user-roles tr:last').find('[id*="cocoonReplaceUniqueId"]').each(function(){
      $(this).attr('id', $(this).attr('id').replace('cocoonReplaceUniqueId', uniqueId));
    });

    createSelect2Remote(true, 'tbody#user-roles tr:last input.select2_remote', '');
  });

  if ($('#li-users').length) {
    if ($('#user_name').val().length == 0 && $('#unity_name').val().length == 0) {
      $('#filter_user_roles').attr('disabled', 'disabled');
    }

    $('#user_name').on('keyup', function() {
      var empty = $(this).val().length == 0;

      if (empty && $('#unity_name').val().length != 0) {
        empty = false;
      }

      enableDisableButton(empty)
    });

    $('#unity_name').on('keyup', function() {
      var empty = $(this).val().length == 0;

      if (empty && $('#user_name').val().length != 0) {
        empty = false;
      }

      enableDisableButton(empty)
    });

    function enableDisableButton(empty) {
      if (empty) {
        $('#filter_user_roles').attr('disabled', 'disabled');
      } else {
        $('#filter_user_roles').attr('disabled', false);
      }
    }

    function goToEditPath() {
      params = {
        user_name: $('#user_name').val(),
        unity_name: $('#unity_name').val(),
        active_permissions_tab: $('#li-general').hasClass('active'),
        active_users_tab: $('#li-users').hasClass('active')
      }

      edit_path = Routes.edit_role_pt_br_path($('#role_id').val()) + '?';

      $.each(params, function(param, value){
        edit_path += param + '=' + value + '&';
      });

      window.location.href = edit_path.slice(0,-1);
    }

    $('#filter_user_roles').click(function() {
      goToEditPath();
    });

    $('#clean_filter').click(function() {
      $('#user_name').val('');
      $('#unity_name').val('');

      goToEditPath();
    });
  }
});
