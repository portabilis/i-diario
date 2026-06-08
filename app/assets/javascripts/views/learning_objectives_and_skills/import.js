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

  $('#confirm-import-btn').on('click', function(e) {
    e.preventDefault();

    var importMode = $('input[name="import_mode"]').val();
    var title, message;

    if (importMode === 'replace') {
      title = 'Confirmar importação (modo substituição)';
      message = 'ATENÇÃO: Todos os registros existentes das séries identificadas no CSV serão <strong>REMOVIDOS</strong> e substituídos pelos novos.<br><br>' +
        'Esta ação <strong>não pode ser desfeita</strong>. Deseja continuar?';
    } else {
      title = 'Confirmar importação';
      message = 'Os novos registros serão adicionados ao banco de dados. Deseja continuar?';
    }

    var $form = $(this).closest('form');

    bootbox.dialog({
      title: title,
      message: message,
      backdrop: true,
      buttons: {
        cancel: {
          label: 'Cancelar',
          className: 'btn-danger'
        },
        confirm: {
          label: 'Confirmar Importação',
          className: 'btn-success',
          callback: function() {
            $form.submit();
          }
        }
      }
    });
  });

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
      $helpText.html('<i class="fa fa-exclamation-triangle"></i> ATENÇÃO: Esse modo de importação remove TODOS os registros existentes da etapa e séries encontradas no CSV, e adiciona os novos. Esta ação não pode ser desfeita.');
      $helpText.attr('class', 'alert alert-warning').show();
    } else {
      $helpText.html('').hide();
    }
  }
});
