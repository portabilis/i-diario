$(function() {
  var selected = [];

  $('body').on('change', '.selected_users', function(event) {
    selected = [];
    $('.selected_users:checked').each(function() {
      selected.push($(this).attr('value'));
    });
    $('#export_selected_selected_users').val(selected);
  });

  $('body').on('change', '#select-all', function(e) {
    selected = [];
    $('.selected_users:checked').each(function() {
      if (!_.contains(selected, $(this).attr('value'))) {
        selected.push($(this).attr('value'));
      }
      $('#export_selected_selected_users').val(selected);
    });

    $('.selected_users').each(function() {
      if (!_.contains(selected, $(this).attr('value'))) {
        selected.pop($(this).attr('value'));
      }
      $('#export_selected_selected_users').val(selected);
    });
  });

  $('#export-selected-users').on('click', function() {
    exportSelectedUsers();
    $('#resources').find('input[type=checkbox]:checked').removeAttr('checked');
    $('#export_selected_selected_users').val('');
  });

  function exportSelectedUsers() {
    var users_id = $('#export_selected_selected_users').val();

    if (!_.isEmpty(users_id)) {
      $.ajax({
        url: Routes.export_selected_users_pt_br_path({ ids: users_id, format: 'csv' })
      });
      $("a#export-selected-users").attr('href', Routes.export_selected_users_pt_br_path({ ids: users_id, format: 'csv' }))
    }else {
      $("a#export-selected-users").attr('href', '#');
      window.alert("Por favor, selecione um ou mais registros primeiro!");
    }
  };
});
