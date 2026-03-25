$(document).ready(function() {
  var $modeSelect = $('#import-mode-select');
  var $helpText = $('#mode-help-text');

  if ($modeSelect.length && $helpText.length) {
    $modeSelect.on('change', updateModeHelp);
    updateModeHelp();
  }

  var $importForm = $('form[action*="validate_csv"]');
  if ($importForm.length) {
    var requiredFields = [
      { inputId: 'import-step-select', groupId: 'step-control-group' },
      { inputId: 'import-mode-select', groupId: 'mode-control-group' },
      { inputId: 'file', groupId: 'file-control-group' }
    ];

    $.each(requiredFields, function(_, field) {
      $('#' + field.inputId).on('change', function() {
        clearFieldError(field.groupId);
      });
    });

    $importForm.on('submit', function(e) {
      var hasErrors = false;

      $.each(requiredFields, function(_, field) {
        clearFieldError(field.groupId);
        var $input = $('#' + field.inputId);

        var val = $input.val();
        if ($input.length && (!val || val === 'empty')) {
          showFieldError(field.groupId);
          hasErrors = true;
        }
      });

      if (hasErrors) {
        e.preventDefault();
      }
    });
  }

  $('.toggle-codes').on('click', function(e) {
    e.preventDefault();
    var grade = $(this).data('grade');
    var $allCodes = $('.all-codes[data-grade="' + grade + '"]');

    if ($allCodes.is(':hidden')) {
      $allCodes.show();
      $(this).text('ocultar');
    } else {
      $allCodes.hide();
      $(this).text('ver todos');
    }
  });

  function showFieldError(groupId) {
    var $group = $('#' + groupId);
    if ($group.length) {
      $group.addClass('error');
      if (!$group.find('span.help-inline').length) {
        $group.append('<span class="help-inline">não pode ficar em branco</span>');
      }
    }
  }

  function clearFieldError(groupId) {
    var $group = $('#' + groupId);
    if ($group.length) {
      $group.removeClass('error');
      $group.find('span.help-inline').remove();
    }
  }

  function updateModeHelp() {
    var value = $modeSelect.val();

    if (value === 'add_new') {
      $helpText.html('<i class="fa fa-info-circle"></i> Mantém todos os registros existentes e adiciona apenas os novos do CSV. Se houver códigos duplicados, a importação será bloqueada.');
      $helpText.attr('class', 'alert alert-info').show();
    } else if (value === 'replace') {
      $helpText.html('<i class="fa fa-exclamation-triangle"></i> ATENÇÃO: Remove TODOS os registros existentes da etapa e séries encontradas no CSV, e adiciona os novos. Esta ação não pode ser desfeita.');
      $helpText.attr('class', 'alert alert-danger').show();
    } else {
      $helpText.html('').hide();
    }
  }
});

function confirmImport() {
  var importMode = $('input[name="import_mode"]');

  if (importMode.length && importMode.val() === 'replace') {
    return confirm(
      'ATENÇÃO: Todos os registros existentes das séries identificadas no CSV serão REMOVIDOS e substituídos pelos novos.\n\n' +
      'Esta ação não pode ser desfeita. Deseja continuar?'
    );
  }

  return confirm('Confirma a importação dos novos registros?');
}
