$(document).ready( function() {
  let days_limit_message = 'É possível registrar frequência de no máximo 10 dias por lançamento, independente da quantidade de dias informados na seleção inicial.';
  $('#flash-messages').html('<div class="alert alert-info fade in"><i class="fa-fw fa fa-info"></i> '  + days_limit_message + ' </div>');

  $('.class-number-checkbox').each( function () {
    markGeneralCheckbox($(this).closest('td'))
  });
})

$(function () {
  let showConfirmation = $('#new_record').val() == 'true';

  $('[name$="[present]"][type=hidden]').remove();

  let modalOptions = {
    title: 'Deseja salvar este lançamento antes de sair?',
    message: 'É necessário apertar o botão "Salvar" ' +
      'ao fim do lançamento de frequência em lote para que seja lançado com sucesso.',
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

$('.general-checkbox').on('change', function() {
  let checked = $(this).prop('checked')
  if (checked) {
    $(this).closest('td').find('.checkbox-frequency-in-batch').removeClass('half-checked')
    $(this).closest('td').find('.checkbox-frequency-in-batch').removeClass('unchecked')
  } else {
    $(this).closest('td').find('.checkbox-frequency-in-batch').addClass('unchecked')
  }
  $(this).closest('td').find('.class-number-checkbox').prop('checked', checked)
  studentAbsencesCount($(this).closest('tr'))
})

$('.class-number-checkbox').on('change', function() {
  if ($(this).is(':checked')) {
    $(this).closest('label').find('.checkbox-frequency-in-batch').removeClass('unchecked')
  } else {
    $(this).closest('label').find('.checkbox-frequency-in-batch').addClass('unchecked')
  }
  markGeneralCheckbox($(this).closest('td'))
  studentAbsencesCount($(this).closest('tr'))
});

function studentAbsencesCount(tr) {
  let count = tr.find('.class-number-checkbox:not(:checked)').length
  tr.find('.student-absences-count').text(count)
}

$('.date-collapse').on('click', function () {
  let index = $(this).index() + 1
  if ($(this).closest('table').find('tbody tr td:nth-child(' + index + ') .class-number-collapse').hasClass('hidden')) {
    $(this).closest('table').find('tbody tr td:nth-child(' + index + ') .class-number-collapse').removeClass('hidden')
    $(this).closest('table').find('tbody tr td:nth-child(' + index + ') .class-number-collapse').removeClass('collapsed')
    $(this).find('#icon-remove').removeClass('hidden')
    $(this).find('#icon-add').addClass('hidden')
    $(this).removeClass('collapsed')
  } else {
    $(this).closest('table').find('tbody tr td:nth-child(' + index + ') .class-number-collapse').addClass('hidden')
    $(this).closest('table').find('tbody tr td:nth-child(' + index + ') .class-number-collapse').addClass('collapsed')
    $(this).find('#icon-add').removeClass('hidden')
    $(this).find('#icon-remove').addClass('hidden')
    $(this).addClass('collapsed')
  }
});

function markGeneralCheckbox(td) {
  let all_checked = td.find('.class-number-checkbox:not(:checked)').length == 0
  let all_not_checked = td.find('.class-number-checkbox:is(:checked)').length == 0
  td.find('.class-number-checkbox:not(:checked)').closest('label').find('.checkbox-frequency-in-batch').addClass('unchecked')
  td.find('.class-number-checkbox:is(:checked)').closest('label').find('.checkbox-frequency-in-batch').removeClass('unchecked')

  if (all_checked) {
    td.find('.general-checkbox').prop('checked', true)
    td.find('.general-checkbox-icon').removeClass('half-checked')
    td.find('.checkbox-frequency-in-batch').removeClass('unchecked')
  } else if (all_not_checked) {
    td.find('.general-checkbox').prop('checked', false)
    td.find('.checkbox-frequency-in-batch').addClass('unchecked')
  } else {
    td.find('.general-checkbox-icon').addClass('half-checked')
    td.find('.general-checkbox-icon').removeClass('unchecked')
    td.find('.general-checkbox').prop('checked', true)
  }
}
