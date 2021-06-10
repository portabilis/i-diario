$(document).ready(validateTypeOfTeaching)
  var $type_of_teaching = $('*[data-id="type_of_teaching"]');

  function validateTypeOfTeaching() {
    for (var i = 0, l = $type_of_teaching.length; i < l; i++) {
      if ($type_of_teaching[i].value != 1) {
        var id = $type_of_teaching[i].id;
        disableCheckbox(id, '_type_of_teaching', '_present')
      }
    }
  }

  function disableCheckbox(id, to, from) {
    id = id.replace(to, from);
    var checkbox = $("#" + id);
    checkbox.prop('disabled', true)
    checkbox.prop('checked', true)
  }

  function enableCheckbox(id, to, from) {
    id = id.replace(to, from);
    var checkbox = $("#" + id);
    checkbox.prop('disabled', false)
    checkbox.prop('checked', true)
  }

$(function () {
  var $type_of_teaching = $('*[data-id="type_of_teaching"]');

  $($type_of_teaching).change(function() {
    var id = this.id;

    if (this.value != 1) {
      disableCheckbox(id, '_type_of_teaching', '_present')
    } else {
      enableCheckbox(id, '_type_of_teaching', '_present')
    }
  });

  var showConfirmation = $('#new_record').val() == 'true';

  // fix to checkboxes work correctly
  $('[name$="[present]"][type=hidden]').remove();

  var modalOptions = {
    title: 'Deseja salvar este lançamento antes de sair?',
    message: 'O Diário de frequência foi atualizado e agora é necessário apertar o botão "Salvar" ' +
             'ao fim do lançamento de frequência para que seja lançado com sucesso.',
    buttons: {
      confirm: { label: 'Salvar', className: 'btn new-save-style' },
      cancel: { label: 'Continuar sem salvar', className: 'btn new-delete-style' }
    }
  };

  $('a, button').on('click', function(e) {
    if (!showConfirmation) {
      return true;
    }

    e.preventDefault();
    showConfirmation = false;

    modalOptions = Object.assign(modalOptions, {
      callback: function(result) {
        if (result) {
          $('input[type=submit]').click();
        } else {
          e.target.click();
        }
      }
    });

    bootbox.confirm(modalOptions);
  });

  setTimeout(function() {
    $('.alert-success').hide();
  }, 10000);

  $('[name$="[present]"]').on('change', function (e) {
    showConfirmation = true;
  });

  $('.daily_frequency').on('submit', function (e) {
    showConfirmation = false;
  });

  $('.alert-success, .alert-danger').fadeTo(700, 0.1).fadeTo(700, 1.0);
});
