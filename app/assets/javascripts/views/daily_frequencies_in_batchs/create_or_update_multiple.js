$(document).ready(function () {
  let beta_title = 'Este recurso ainda está em processo de desenvolvimento e pode apresentar problemas'
  let img_src = $('#image-beta').attr('src');
  $('.fa-check-square-o').closest('h2').after(`<img src="${img_src}" class="beta-badge" style="margin-bottom: 9px; margin-left: 5px" title="${beta_title}">`);

  $('[data-id="type_of_teaching"]').each(function (index, type_of_teaching) {
    $(type_of_teaching).on('change', function () {
      var inputs = $(this).closest('tr').find('[data-id="type_of_teaching_input"]')
      var value = $(this).val()
      inputs.each(function (index, input) {
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

  $('.date-collapse').each(function () {
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

  $('a:not(.no-confirm), button:not(.no-confirm)').on('click', function (e) {
    if (!showConfirmation) {
      return true;
    }

    e.preventDefault();
    showConfirmation = false;

    modalOptions = Object.assign(modalOptions, {
      callback: function (result) {
        if (result) {
          $('input[type=submit].new-save-style').click();
        } else {
          e.target.click();
        }
      }
    });

    bootbox.confirm(modalOptions);
  });

  setTimeout(function () {
    $('.alert-success').hide();
  }, 10000);

  $('[name$="[present]"]').on('change', function (e) {
    showConfirmation = true;
  });

  $('.daily_frequency').on('submit', function (e) {
    e.preventDefault();
    showConfirmation = false;
    submitFormAsJSON();
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

  $("label.checkbox-frequency:not(.checkbox-batch) input[type=checkbox]").click(function () {
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

  $("label.checkbox-batch input[type=checkbox]").click(function () {
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

function submitFormAsJSON() {
  const form = document.getElementById('frequency-batch-form');
  const submitBtn = document.getElementById('save-frequencies-btn');
  const formData = new FormData(form);

  showBatchLoadingScreen();

  submitBtn.disabled = true;
  submitBtn.textContent = 'Salvando...';

  const jsonData = serializeFormToJSON(formData);

  $.ajax({
    url: form.action,
    method: 'POST',
    contentType: 'application/json',
    data: JSON.stringify(jsonData),
    beforeSend: function (xhr) {
      xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
    },
    success: function (response) {
      if (response.success) {
        updateLoadingScreen('success', response.message);

        setTimeout(function () {
          window.location.href = response.redirect_url;
        }, 1500);
      } else {
        updateLoadingScreen('error', 'Erro nos dados enviados');

        setTimeout(function () {
          hideBatchLoadingScreen();
          handleFormErrors(response.errors || [response.message]);
        }, 2000);
      }
    },
    error: function (xhr, status, error) {
      let errorMessage = 'Erro ao salvar frequências.';

      if (xhr.responseJSON) {
        errorMessage = xhr.responseJSON.message || errorMessage;
        updateLoadingScreen('error', errorMessage);

        setTimeout(function () {
          hideBatchLoadingScreen();
          handleFormErrors(xhr.responseJSON.errors || [errorMessage]);
        }, 2000);
      } else {
        updateLoadingScreen('error', errorMessage);

        setTimeout(function () {
          hideBatchLoadingScreen();
          showNotification(errorMessage, 'error');
        }, 2000);
      }
    },
    complete: function () {
      // Reabilitar botão (a tela de loading é controlada nos handlers success/error)
      submitBtn.disabled = false;
      submitBtn.textContent = 'Salvar';
    }
  });
}

function serializeFormToJSON(formData) {
  const data = {
    unity_id: formData.get('unity_id'),
    classroom_id: formData.get('classroom_id'),
    discipline_id: formData.get('discipline_id'),
    frequency_type: formData.get('frequency_type'),
    period: formData.get('period'),
    start_date: formData.get('start_date'),
    end_date: formData.get('end_date'),
    receive_email_confirmation: formData.get('frequency_in_batch_form[receive_email_confirmation]') === '1',
    daily_frequencies: {}
  };

  for (const [key, value] of formData.entries()) {
    if (key.includes('[daily_frequency][daily_frequencies]')) {
      const matches = key.match(/\[daily_frequency\]\[daily_frequencies\]\[([^\]]+)\](.*)/);
      if (matches) {
        const frequencyId = matches[1];
        const fieldPath = matches[2];

        if (!data.daily_frequencies[frequencyId]) {
          data.daily_frequencies[frequencyId] = {
            students_attributes: {}
          };
        }

        if (fieldPath.includes('[date]')) {
          data.daily_frequencies[frequencyId].date = value;
        } else if (fieldPath.includes('[class_number]')) {
          data.daily_frequencies[frequencyId].class_number = value;
        } else if (fieldPath.includes('[students_attributes]')) {
          const studentMatches = fieldPath.match(/\[students_attributes\]\[([^\]]+)\]\[([^\]]+)\]/);
          if (studentMatches) {
            const studentId = studentMatches[1];
            const fieldName = studentMatches[2];

            if (!data.daily_frequencies[frequencyId].students_attributes[studentId]) {
              data.daily_frequencies[frequencyId].students_attributes[studentId] = {};
            }

            let processedValue = value;
            if (fieldName === 'present' || fieldName === 'active' || fieldName === 'dependence') {
              processedValue = value === '1' || value === 'true';
            } else if (fieldName === 'student_id' || fieldName === 'daily_frequency_id') {
              processedValue = value ? parseInt(value) : null;
            }

            data.daily_frequencies[frequencyId].students_attributes[studentId][fieldName] = processedValue;
          }
        }
      }
    }
  }

  return data;
}

function showNotification(message, type) {
  $('.ajax-notification').remove();

  const alertClass = type === 'success' ? 'alert-success' : 'alert-danger';
  const icon = type === 'success' ? 'fa-check' : 'fa-exclamation-triangle';

  const notification = $(`
    <div class="alert ${alertClass} ajax-notification" style="position: fixed; top: 20px; right: 20px; z-index: 9999; max-width: 400px;">
      <i class="fa ${icon}"></i> ${message}
      <button type="button" class="close" data-dismiss="alert">&times;</button>
    </div>
  `);

  $('body').append(notification);

  setTimeout(function () {
    notification.fadeOut();
  }, 5000);
}

function handleFormErrors(errors) {
  let errorMessage = 'Erro ao processar dados:';
  if (Array.isArray(errors)) {
    errorMessage += '<ul>';
    errors.forEach(function (error) {
      errorMessage += '<li>' + error + '</li>';
    });
    errorMessage += '</ul>';
  } else {
    errorMessage += ' ' + errors;
  }

  showNotification(errorMessage, 'error');
}

function showBatchLoadingScreen() {
  let $loadingClone = $('#page-loading').clone(true);
  $loadingClone.attr('id', 'frequency-batch-loading');

  $loadingClone.html(`
    <div style="
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      text-align: center;
      background: rgba(33, 37, 41, 0.9);
      color: white;
      padding: 30px 40px;
      border-radius: 8px;
      min-width: 300px;
      box-shadow: 0 4px 20px rgba(0,0,0,0.3);
    ">
      <div style="margin-bottom: 15px;">
        <i class="fa fa-cog fa-spin" style="font-size: 42px; color: #1ab394;"></i>
      </div>
      
      <div style="font-size: 18px; font-weight: bold; margin-bottom: 10px;">
        Processando Frequências
      </div>
      
      <div id="progress-message" style="font-size: 14px; margin-bottom: 20px; color: #ccc;">
        Salvando frequências em lote...
      </div>
      
      <div class="progress-container" style="
        width: 100%;
        background: rgba(255,255,255,0.2);
        border-radius: 10px;
        height: 20px;
        margin-bottom: 10px;
        overflow: hidden;
      ">
        <div class="progress-bar" style="
          width: 0%;
          height: 100%;
          background: linear-gradient(90deg, #1ab394 0%, #2ed8b6 100%);
          border-radius: 10px;
          transition: width 0.3s ease;
          position: relative;
        ">
          <div style="
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: linear-gradient(90deg, 
              transparent 0%, 
              rgba(255,255,255,0.3) 50%, 
              transparent 100%);
            animation: progress-shimmer 2s infinite;
          "></div>
        </div>
      </div>
      
      <div class="progress-text" style="font-size: 14px; color: #1ab394; font-weight: bold;">
        0%
      </div>
    </div>
  `);

  if (!$('#frequency-loading-styles').length) {
    $('head').append(`
      <style id="frequency-loading-styles">
        @keyframes progress-shimmer {
          0% { transform: translateX(-100%); }
          100% { transform: translateX(100%); }
        }
      </style>
    `);
  }

  $loadingClone.css({
    'position': 'fixed',
    'top': '0',
    'left': '0',
    'width': '100%',
    'height': '100%',
    'background': 'rgba(0,0,0,0.7)',
    'z-index': '999999'
  });

  $('body').append($loadingClone);
  $loadingClone.removeClass('hidden');

  startProgressAnimation();
}

function hideBatchLoadingScreen() {
  currentProgress = 0;
  currentStepIndex = 0;

  $('#frequency-batch-loading').fadeOut(300, function () {
    $(this).remove();
  });
}

let currentProgress = 0;
let progressSteps = [];
let currentStepIndex = 0;
let stepStartTime = 0;

function startProgressAnimation() {
  currentProgress = 5;
  currentStepIndex = 0;

  progressSteps = [
    { progress: 5, message: "Preparando dados...", duration: 200 },
    { progress: 15, message: "Validando informações...", duration: 300 },
    { progress: 25, message: "Processando alunos...", duration: 800 },
    { progress: 45, message: "Salvando frequências...", duration: 1200 },
    { progress: 65, message: "Atualizando registros...", duration: 900 },
    { progress: 80, message: "Finalizando processamento...", duration: 600 },
    { progress: 90, message: "Aguardando confirmação do servidor...", duration: 0 }
  ];

  updateProgress(5, "Iniciando processamento...");
  processNextStep();
}

function processNextStep() {
  if (currentStepIndex >= progressSteps.length) return;

  const step = progressSteps[currentStepIndex];
  stepStartTime = Date.now();

  updateProgressMessage(step.message);

  if (step.duration > 0) {
    animateStepProgress(step);
  } else {
    updateProgress(step.progress, step.message);
  }
}

function animateStepProgress(step) {
  const startProgress = currentProgress;
  const targetProgress = step.progress;
  const duration = step.duration;
  const startTime = stepStartTime;

  const animate = () => {
    const elapsed = Date.now() - startTime;
    const progressRatio = Math.min(elapsed / duration, 1);

    const easedProgress = easeOutQuart(progressRatio);
    const newProgress = startProgress + (targetProgress - startProgress) * easedProgress;

    updateProgress(Math.round(newProgress));

    if (progressRatio < 1) {
      requestAnimationFrame(animate);
    } else {
      currentProgress = targetProgress;
      currentStepIndex++;

      setTimeout(() => {
        processNextStep();
      }, 100);
    }
  };

  requestAnimationFrame(animate);
}

function easeOutQuart(t) {
  return 1 - Math.pow(1 - t, 4);
}

function updateProgress(percentage, message) {
  const $loading = $('#frequency-batch-loading');
  if ($loading.length) {
    $loading.find('.progress-bar').css('width', percentage + '%');
    $loading.find('.progress-text').text(percentage + '%');

    if (message) {
      $loading.find('#progress-message').text(message);
    }
  }
}

function updateProgressMessage(message) {
  const $loading = $('#frequency-batch-loading');
  if ($loading.length) {
    $loading.find('#progress-message').text(message);
  }
}

function completeProgress() {
  currentProgress = 100;
  updateProgress(100, "Processamento concluído!");
}

function updateLoadingScreen(status, message) {
  const $loadingScreen = $('#frequency-batch-loading');

  if (status === 'success') {
    completeProgress();

    setTimeout(function () {
      $loadingScreen.find('.fa-cog').removeClass('fa-spin fa-cog').addClass('fa-check-circle');
      $loadingScreen.find('.fa-check-circle').css('color', '#1ab394');

      $loadingScreen.find('div:contains("Processando Frequências")').text('Frequências Salvas!');
      $loadingScreen.find('#progress-message').text('Processamento concluído. Redirecionando...');

      $loadingScreen.find('.progress-container').html(`
        <div style="
          color: #1ab394;
          font-size: 16px;
          font-weight: bold;
          text-align: center;
          padding: 10px;
        ">
          <i class="fa fa-check-circle" style="margin-right: 8px;"></i>
          Concluído com Sucesso
        </div>
      `);

      $loadingScreen.find('.progress-text').text('100%').css('color', '#1ab394');
    }, 300);

  } else if (status === 'error') {
    $loadingScreen.find('.fa-cog').removeClass('fa-spin fa-cog').addClass('fa-exclamation-triangle');
    $loadingScreen.find('.fa-exclamation-triangle').css('color', '#ed5565');

    $loadingScreen.find('div:contains("Processando Frequências")').text('Erro no Processamento');
    $loadingScreen.find('#progress-message').text(message || 'Ocorreu um erro ao processar as frequências.');

    $loadingScreen.find('.progress-container').html(`
      <div style="
        color: #ed5565;
        font-size: 16px;
        font-weight: bold;
        text-align: center;
        padding: 10px;
      ">
        <i class="fa fa-exclamation-triangle" style="margin-right: 8px;"></i>
        Erro no Processamento
      </div>
    `);

    $loadingScreen.find('.progress-text').text('Erro').css('color', '#ed5565');
  }
}
