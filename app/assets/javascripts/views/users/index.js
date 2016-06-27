$(function() {
  var selected = [];

  $('tr#selected_users_csv').on('change', function(e) {
    selected = [];
    $('#selected_users_csv input:checked').each(function() {
      if (!_.contains(selected, $(this).attr('value'))) {
        selected.push($(this).attr('value'));
      }
      $('#export_selected_selected_users').val(selected);
    });
  });

  $('#select-all').on('change', function(e) {
    selected = [];
    $('#selected_users_csv input:checked').each(function() {
      if (!_.contains(selected, $(this).attr('value'))) {
        selected.push($(this).attr('value'));
      }
      $('#export_selected_selected_users').val(selected);
    });
  });

  $('#export-selected-users').on('click', function() {
    exportSelectedUsers();
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
      $("a#export-selected-users").attr('href', '#')
    }
  };
});
