$(document).ready( function() {
  let beta_title = 'Este recurso ainda está em processo de desenvolvimento e pode apresentar problemas'
  let img_src = $('#image-beta').attr('src');
  $('.fa-check-square-o').closest('h2').after(`<img src="${img_src}" class="beta-badge" style="margin-bottom: 9px; margin-left: 5px" title="${beta_title}">`);

  $('[data-id="type_of_teaching"]').each( function (index, type_of_teaching) {
    $(type_of_teaching).on('change', function () {
      var inputs = $(this).closest('tr').find('[data-id="type_of_teaching_input"]')
      var value = $(this).val()
      inputs.each(function(index, input) {
        $(input).val(value)
      })
      var checkbox = $(this).closest('tr').find('td .general-checkbox')
      var disabled = value != 1
      if (disabled) {
        checkbox.prop('disabled', disabled)
        checkbox.prop('checked', true)
        checkbox.closest('label').addClass('state-disabled');
        checkbox.closest('td').find('.class-number-checkbox').prop('checked', true)
        checkbox.closest('label').find('.general-checkbox-icon').removeClass('unchecked')
      } else {
        checkbox.closest('label:not(.never-change)').find('.general-checkbox:not(.never-change)').prop('disabled', disabled)
        checkbox.closest('label:not(.never-change)').removeClass('state-disabled');
      }
    }).trigger('change');
  })

  $('.class-number-checkbox').each( function () {
    markGeneralCheckbox($(this).closest('td'))
  });

  $('.date-collapse').each( function () {
    let index = $(this).index() + 1
    $(this).closest('table').find('tbody tr td:nth-child(' + index + ') .class-number-collapse').addClass('hidden')
    $(this).closest('table').find('tbody tr td:nth-child(' + index + ') .class-number-collapse').addClass('collapsed')
    $(this).addClass('collapsed')
    $(this).find('#icon-remove').addClass('hidden')
  });
})

$(function () {
  let showConfirmation = $('#new_record').val() == 'true';

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
  let count = tr.find('.class-number-checkbox:not(:checked)').not('.inactive').length
  tr.find('.student-absences-count').text(count)
}

$('.date-collapse').on('click', function () {
  let index = $(this).index() + 1
  console.log($(this).data('count'))
  if ($(this).data('count') > 1) {
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
