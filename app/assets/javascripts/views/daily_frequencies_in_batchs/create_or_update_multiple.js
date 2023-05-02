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
        checkbox.closest('td').find('.class-number-checkbox:not(.justified-absence-checkbox)').prop('checked', true)
        checkbox.closest('label').find('.general-checkbox-icon').removeClass('unchecked')
      } else {
        checkbox.closest('label:not(.never-change)').find('.general-checkbox:not(.never-change)').prop('disabled', disabled)
        checkbox.closest('label:not(.never-change)').removeClass('state-disabled');
      }
    }).trigger('change');
  })

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

  $('a:not(.no-confirm), button:not(.no-confirm)').on('click', function(e) {
    if (!showConfirmation) {
      return true;
    }

    e.preventDefault();
    showConfirmation = false;

    modalOptions = Object.assign(modalOptions, {
      callback: function(result) {
        if (result) {
          $('input[type=submit].new-save-style').click();
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

function studentAbsencesCount(tr) {
  let count = tr.find('label.checkbox-frequency:not(.checkbox-batch) input[type=checkbox]:not(:checked)').not('.inactive').length
  tr.find('.student-absences-count').text(count)
}

function updateCheckboxes(el, init = false) {
  let checkboxes = el.closest('td').find('label.checkbox-frequency:not(.checkbox-batch) input[type=checkbox]');
  let general = el.closest('td').find('label.checkbox-batch input[type=checkbox]');
  let total = checkboxes.length;
  let present = 0;
  let justified = 0;
  let absent = 0;

  checkboxes.each(function () {
    let checked = $(this).prop('checked');
    let indeterminate = $(this).prop('indeterminate') || $(this).closest('label').hasClass('justified');

    if (checked && !indeterminate) {
      present++;
    } else if (!checked && indeterminate) {
      justified++;
    } else {
      absent++;
    }
  });

  if (present == total) {
    general.data('status', 'absent');
    general.prop('indeterminate', false);
    general.prop('checked', true);
    general.closest('label').removeClass('justified').removeClass('partial-absence');
  } else if (justified == total) {
    general.data('status', 'present');
    general.prop('indeterminate', true);
    general.prop('checked', false);
    general.closest('label').addClass('justified').removeClass('partial-absence');

    // Garante que um dia já justificado não possa ser alterado
    if (init) {
      general.prop('disabled', true);
    }
  } else if (absent == total) {
    general.data('status', 'justified');
    general.prop('indeterminate', false);
    general.prop('checked', false);
    general.closest('label').removeClass('justified').removeClass('partial-absence');
  } else {
    general.data('status', 'absent');
    general.prop('indeterminate', false);
    general.prop('checked', true);
    general.closest('label').removeClass('justified').addClass('partial-absence');
  }

  studentAbsencesCount(el.closest('tr'));
}

$('.date-collapse').on('click', function () {
  let index = $(this).index() + 1
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

$(document).ready(function () {
  $("label.checkbox-frequency:not(.checkbox-batch) input[type=checkbox]").each(function () {
    updateCheckboxes($(this), true);
  });

  $("label.checkbox-frequency:not(.checkbox-batch) input[type=checkbox]").click(function() {
    let el = $(this);

    el.closest('div').find('.hidden-justified').prop('disabled', true).val(null);

    switch (el.data('status')) {
      case 'present':
        el.data('status', 'absent');
        el.prop('indeterminate', false);
        el.prop('checked', true);
        el.closest('label').removeClass('justified');
        break;

      case 'justified':
        el.data('status', 'present');
        el.prop('indeterminate', true);
        el.prop('checked', false);
        el.closest('label').addClass('justified');
        el.closest('div').find('.hidden-justified').prop('disabled', false).val(-1);
        break;

      case 'absent':
      default:
        el.data('status', 'justified');
        el.prop('indeterminate', false);
        el.prop('checked', false);
        el.closest('label').removeClass('justified');
    }

    updateCheckboxes(el);
  });

  $("label.checkbox-batch input[type=checkbox]").click(function() {
    let el = $(this);
    let td = el.closest('td');

    el.closest('label').removeClass('partial-absence');
    td.find('.hidden-justified').prop('disabled', true).val(null);

    switch (el.data('status')) {
      case 'present':
        td.find('label.checkbox-frequency input[type=checkbox]').data('status', 'absent');
        td.find('label.checkbox-frequency input[type=checkbox]').prop('indeterminate', false);
        td.find('label.checkbox-frequency input[type=checkbox]').prop('checked', true);
        td.find('label').removeClass('justified');
        break;

      case 'justified':
        td.find('label.checkbox-frequency input[type=checkbox]').data('status', 'present');
        td.find('label.checkbox-frequency input[type=checkbox]').prop('indeterminate', true);
        td.find('label.checkbox-frequency input[type=checkbox]').prop('checked', false);
        td.find('label').addClass('justified');
        td.find('.hidden-justified').prop('disabled', false).val(-1);
        break;

      case 'absent':
      default:
        td.find('label.checkbox-frequency input[type=checkbox]').data('status', 'justified');
        td.find('label.checkbox-frequency input[type=checkbox]').prop('indeterminate', false);
        td.find('label.checkbox-frequency input[type=checkbox]').prop('checked', false);
        td.find('label').removeClass('justified');
    }

    studentAbsencesCount(el.closest('tr'));
  });
});
