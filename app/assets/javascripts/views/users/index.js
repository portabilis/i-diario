$(function() {
  var selected = [];

  $(document).on('click', 'ul.pagination > li > a', function(e) {
    var onPageChange = new CustomEvent('onPageChange');
    document.dispatchEvent(onPageChange);
  });

  document.addEventListener("onPageChange", function (e) {
    $("#select-all").prop("checked", false)
  })

  $('body').on('change', '.selected_users', function(event) {
    selected = $('#export_selected_selected_users').val().split(",");

    if ($(this).prop('checked')) {
      selected.push($(this).attr('value'))
    } else {
      selected.pop($(this).attr('value'))
    }

    $('#export_selected_selected_users').val(selected);
  });

  $('body').on('change', '#select-all', function(e) {
    selected = $('#export_selected_selected_users').val().split(",");

    $('.selected_users:checked').each(function() {
      if (!_.includes(selected, $(this).attr('value'))) {
        selected.push($(this).attr('value'));
      }
      $('#export_selected_selected_users').val(selected);
    });

    $('.selected_users').each(function() {
      if (!_.includes(selected, $(this).attr('value'))) {
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
      window.alert("Por favor, selecione um ou mais registros primeiro.");
    }
  };

  $('input.string').bind('keypress', function(e) {
    if (e.keyCode == 13) {
      e.preventDefault();
    }
  });

  $('.destroy-button').each(function() {
    var search_by_name = $('#search_by_name').val();
    var search_by_cpf = $('#search_by_cpf').val();
    var search_email = $('#search_email').val();
    var search_login = $('#search_login').val();
    var search_status = $('#search_status').val();
    var params = '';

    if (search_by_name) {
      params += '&search[by_name]=' + search_by_name;
    }

    if (search_by_cpf) {
      params += '&search[by_cpf]=' + search_by_cpf;
    }

    if (search_email) {
      params += '&search[email]=' + search_email;
    }

    if (search_login) {
      params += '&search[login]=' + search_login;
    }

    if (search_status) {
      params += '&search[status]=' + search_status;
    }

    var _href = $(this).attr("href");

    $(this).attr("href", _href + params.replace('&', '?'));
  });
  $('#search_by_cpf').inputmask("999.999.999-99");
});
