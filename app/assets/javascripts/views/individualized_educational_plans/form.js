$(function() {
  'use strict';

  var $wizard = $('#pei-wizard');
  if ($wizard.length === 0) { return; }

  var flashMessages = new FlashMessages();

  // Etapas do topo do wizard (fuelux steps); os painéis top-level ficam em .tab-content direto do wizard
  var $steps = $wizard.find('.fuelux .steps li');
  var $panes = $wizard.children('.tab-content').children('.tab-pane');
  // "input." obrigatório: o select2 v3 copia as classes do input para o container div que ele
  // insere ANTES do input — sem o prefixo, $('.iep-student-select') casa com o div primeiro e
  // .val() devolve undefined mesmo com aluno selecionado.
  var $studentSelect = $('input.iep-student-select');
  // Na versão publicada os dados do aluno vêm congelados do snapshot: não busca no i-Educar.
  var studentFetchEnabled = $wizard.data('student-fetch') !== 'off';
  // Laudos: nunca congelados — são sempre os do cadastro do aluno no i-Educar, inclusive na
  // versão publicada (que busca pelo plano de origem, já que o plano da tela é um stand-in).
  var $medicalReports = $('#iep-medical-reports');
  var medicalReportsPlanId = $wizard.data('medical-reports-plan-id');

  // ---- Navegação em passos (fuelux wizard: badge numerada + chevron) ----
  function currentIndex() {
    return $steps.index($steps.filter('.active'));
  }

  function showStep(index) {
    if (index < 0 || index >= $steps.length) { return; }

    // Destaca somente a etapa atual (o preenchimento não é sequencial — sem estado "concluída")
    $steps.each(function(stepIndex) {
      $(this).toggleClass('active', stepIndex === index);
      $(this).find('.badge').toggleClass('badge-info', stepIndex === index);
    });

    $panes.removeClass('active').eq(index).addClass('active');
    refreshButtons();
  }

  function refreshButtons() {
    var index = currentIndex();
    var last = $steps.length - 1;

    $('.pei-wizard-prev').toggle(index > 0);
    $('.pei-wizard-next').toggle(index < last);
    $('.pei-wizard-finish').toggle(index === last);
  }

  $('.pei-wizard-next').on('click', function() { showStep(currentIndex() + 1); });
  $('.pei-wizard-prev').on('click', function() { showStep(currentIndex() - 1); });
  $steps.on('click', function() { showStep($steps.index(this)); });
  refreshButtons();

  // ---- Laudos (seção 1): lista lida do cadastro do aluno no i-Educar ----
  // Identifica o aluno pelo plano (edição/visualização/versão) ou pelo aluno selecionado
  // (criação, quando o plano ainda não existe). Recebe o studentId de quem chama, em vez de
  // reler o select: na criação a releitura volta vazia no callback do AJAX e o laudo acabava
  // renderizado como texto, sem link.
  function medicalReportIdentity(studentId) {
    if (medicalReportsPlanId) { return { plan_id: medicalReportsPlanId }; }

    if (!studentId || studentId === 'empty') { return null; }

    var identity = { student_id: studentId };
    var elaboratedAt = $('.iep-elaborated-at').val();
    if (elaboratedAt) { identity.elaborated_at = elaboratedAt; }

    return identity;
  }

  function medicalReportsMessage(text) {
    $medicalReports.empty().append(
      $('<tr>').append($('<td>').attr('colspan', 2).addClass('text-muted').text(text))
    );
  }

  // .text() em vez de HTML: o nome do arquivo vem do i-Educar e não é confiável para
  // interpolar como markup.
  function renderMedicalReports(reports, unavailable, identity) {
    if ($medicalReports.length === 0) { return; }

    if (unavailable) {
      medicalReportsMessage($medicalReports.data('unavailable-text'));
      return;
    }

    if (!reports || reports.length === 0) {
      medicalReportsMessage($medicalReports.data('empty-text'));
      return;
    }

    $medicalReports.empty();

    $.each(reports, function(_index, report) {
      var $name = $('<a>')
        .attr('href', Routes.open_medical_report_individualized_educational_plans_pt_br_path(
          $.extend({ name: report.name, created_at: report.created_at }, identity)
        ))
        .attr('target', '_blank')
        .text(report.name);

      $medicalReports.append(
        $('<tr>').append($('<td>').append($name)).append($('<td>').text(report.sent_at || ''))
      );
    });
  }

  // Busca dedicada: usada onde o prefill do aluno não roda (versão publicada), já que os
  // laudos não são congelados no snapshot.
  function fetchMedicalReports(studentId) {
    if ($medicalReports.length === 0) { return; }

    var identity = medicalReportIdentity(studentId);
    if (!identity) { medicalReportsMessage($medicalReports.data('pending-text')); return; }

    $.ajax({
      url: Routes.medical_reports_individualized_educational_plans_pt_br_path(
        $.extend({ format: 'json' }, identity)
      ),
      dataType: 'json',
      success: function(data) {
        renderMedicalReports(data.medical_reports, data.medical_reports_unavailable, identity);
      },
      error: function(jqXHR, textStatus) {
        renderMedicalReports([], true, identity);
        flashMessages.error(medicalReportsErrorMessage(jqXHR, textStatus));
      }
    });
  }

  function sessionExpiredMessage(jqXHR, textStatus) {
    var status = jqXHR && jqXHR.status;

    if (status === 401 || status === 403 || textStatus === 'parsererror') {
      return 'Sua sessão expirou ou você não tem acesso a este plano. Recarregue a página e tente novamente.';
    }

    return null;
  }

  function medicalReportsErrorMessage(jqXHR, textStatus) {
    return sessionExpiredMessage(jqXHR, textStatus) || 'Não foi possível consultar os laudos no i-Educar.';
  }

  // ---- Envio de laudo (seção 1): grava direto no cadastro do aluno no i-Educar ----
  // O envio é IRREVERSÍVEL pelo i-Diário (a remoção só existe no cadastro do aluno no i-Educar).
  // Por isso o fluxo tem duas etapas: "Adicionar laudo" cria uma linha PENDENTE (removível) e
  // "Enviar laudo" pede confirmação antes de gravar. Finalizar com pendência é bloqueado abaixo.
  var $addButton = $('#iep-medical-report-add-button');
  var $sendButton = $('#iep-medical-report-send-button');
  var $uploadFile = $('#iep-medical-report-file');
  var $pendingReports = $('#iep-medical-reports-pending');
  var $sendModal = $('#iep-medical-report-send-modal');
  var $sendConfirm = $('#iep-medical-report-send-confirm');
  var sendButtonHtml = $sendButton.html();
  var pendingUploads = [];
  var pendingKey = 0;
  var uploading = false;

  // Espelho das regras do endpoint do i-Educar (tipo/tamanho) para feedback imediato — o
  // servidor revalida antes de enviar.
  var UPLOAD_EXTENSIONS = ['jpg', 'jpeg', 'png', 'pdf', 'doc'];
  var UPLOAD_MAX_SIZE = 2 * 1024 * 1024;

  function uploadValidationError(file) {
    var extension = (file.name.split('.').pop() || '').toLowerCase();
    if (UPLOAD_EXTENSIONS.indexOf(extension) === -1) {
      return 'Deve ser enviado um arquivo do tipo jpg, jpeg, png, pdf ou doc.';
    }

    if (file.size > UPLOAD_MAX_SIZE) { return 'Não são permitidos arquivos com mais de 2MB.'; }

    return null;
  }

  function refreshSendButton() {
    $sendButton.prop('disabled', pendingUploads.length === 0);
  }

  // Erros de anexo/envio aparecem junto da tabela de laudos: o flash do topo fica fora da
  // tela nesta altura do formulário.
  function clearMedicalReportError() {
    $pendingReports.find('.iep-medical-report-error-row').remove();
  }

  function showMedicalReportError(message) {
    clearMedicalReportError();
    $pendingReports.append(
      $('<tr class="iep-medical-report-error-row">').append(
        $('<td colspan="2">').append($('<span class="help-inline error">').text(message))
      )
    );
  }

  function addPendingRow(item) {
    var $remove = $('<button type="button" class="btn btn-danger btn-sm iep-medical-report-remove"></button>')
      .text($pendingReports.data('remove-text'));

    var $badge = $('<span class="label label-warning pull-right">')
      .css({ display: 'inline-block', width: 'auto' })
      .text($pendingReports.data('not-sent-text'));

    $pendingReports.append(
      $('<tr>').attr('data-pending-key', item.key)
        .append(
          $('<td>').css('vertical-align', 'middle').append(
            $('<span>').text(item.file.name),
            $badge,
            $('<div class="help-inline error iep-medical-report-row-error" style="display: none;"></div>')
          )
        )
        .append($('<td>').css('vertical-align', 'middle').append($remove))
    );
  }

  function setUploadSending(sending) {
    $addButton.prop('disabled', sending);
    $pendingReports.find('button').prop('disabled', sending);
    $('.pei-wizard-finish').prop('disabled', sending);
    $sendConfirm.prop('disabled', sending);
    if (sending) {
      $sendButton.prop('disabled', true);
      $sendButton.text($sendButton.data('sending-text'));
    } else {
      $sendButton.html(sendButtonHtml);
      refreshSendButton();
    }
  }

  function clearPendingUploads() {
    if (pendingUploads.length === 0) { return false; }

    pendingUploads = [];
    $pendingReports.find('tr[data-pending-key]').remove();
    refreshSendButton();

    return true;
  }

  function discardPendingUploadsOnStudentChange() {
    if (clearPendingUploads()) {
      showMedicalReportError('O laudo anexado foi descartado porque o aluno mudou. Anexe novamente para enviar.');
    }
  }

  $addButton.on('click', function() { $uploadFile.trigger('click'); });

  $uploadFile.on('change', function() {
    var file = this.files && this.files[0];
    if (!file) { return; }

    $uploadFile.val('');

    var validationError = uploadValidationError(file);
    if (validationError) {
      showMedicalReportError(file.name + ': ' + validationError);
      return;
    }

    clearMedicalReportError();

    var item = { key: (pendingKey += 1), file: file };
    pendingUploads.push(item);
    addPendingRow(item);
    refreshSendButton();
  });

  $pendingReports.on('click', '.iep-medical-report-remove', function() {
    var key = $(this).closest('tr').data('pending-key');

    pendingUploads = pendingUploads.filter(function(item) { return item.key !== key; });
    $(this).closest('tr').remove();
    clearMedicalReportError();
    refreshSendButton();
  });

  function selectedStudentName() {
    try {
      var data = $studentSelect.select2('data');

      return (data && (data.text || data.name)) || '';
    } catch (error) {
      if (window.console) { console.error('PEI: não foi possível ler o aluno selecionado', error); }

      return '';
    }
  }

  $sendButton.on('click', function() {
    if (pendingUploads.length === 0) { return; }

    if (!medicalReportIdentity($studentSelect.val())) {
      showMedicalReportError('Selecione o aluno antes de enviar o laudo.');
      return;
    }

    $sendModal.find('.iep-medical-report-send-student').show()
      .find('span').text(selectedStudentName() || 'não foi possível identificar — confira o aluno na seção 1');

    $sendModal.modal('show');
  });

  $sendConfirm.on('click', function() {
    if (uploading) { return; }

    $sendModal.modal('hide');

    var identity = medicalReportIdentity($studentSelect.val());
    if (!identity) { showMedicalReportError('Selecione o aluno antes de enviar o laudo.'); return; }

    clearMedicalReportError();
    $pendingReports.find('.iep-medical-report-row-error').hide().empty();

    uploading = true;
    setUploadSending(true);
    sendNextPending(identity, false);
  });

  // Envia a fila um a um (o endpoint recebe um arquivo por request). Para no primeiro erro:
  // o que falhou continua pendente, pode ser removido ou reenviado.
  function sendNextPending(identity, sentAny) {
    var item = pendingUploads[0];
    if (!item) { finishSending(identity, sentAny); return; }

    var formData = new FormData();
    formData.append('file', item.file);
    $.each(identity, function(key, value) { formData.append(key, value); });

    $.ajax({
      url: Routes.upload_medical_report_individualized_educational_plans_pt_br_path(),
      type: 'POST',
      data: formData,
      processData: false,
      contentType: false,
      dataType: 'json',
      headers: { 'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content') },
      success: function(data) {
        pendingUploads.shift();
        $pendingReports.find('tr[data-pending-key="' + item.key + '"]').remove();
        flashMessages.success(_.escape((data && data.message) || 'Laudo enviado para o cadastro do aluno no i-Educar.'));
        sendNextPending(identity, true);
      },
      error: function(jqXHR, textStatus) {
        var message = (jqXHR && jqXHR.responseJSON && jqXHR.responseJSON.message) ||
                      sessionExpiredMessage(jqXHR, textStatus) ||
                      'Não foi possível enviar o laudo ao i-Educar.';

        $pendingReports.find('tr[data-pending-key="' + item.key + '"] .iep-medical-report-row-error')
          .text(message)
          .show();
        finishSending(identity, sentAny);
      }
    });
  }

  function finishSending(identity, sentAny) {
    uploading = false;
    setUploadSending(false);

    if (!sentAny) { return; }

    if (identity.plan_id) {
      fetchMedicalReports();
    } else {
      fetchStudentData(identity.student_id);
    }
  }

  // Finalizar com laudo anexado e não enviado descartaria o anexo em silêncio: bloqueia a
  // abertura do modal de finalização (stopPropagation barra o data-toggle do Bootstrap,
  // delegado no document) e volta para a seção 1, onde está a pendência.
  $('.pei-wizard-finish').on('click', function(event) {
    if (pendingUploads.length === 0) { return; }

    event.preventDefault();
    event.stopPropagation();
    showStep(0);
    showMedicalReportError('Há laudo anexado que ainda não foi enviado ao i-Educar. Envie ou remova o anexo antes de finalizar.');
    flashMessages.error(
      'Há laudo anexado que ainda não foi enviado ao i-Educar. Envie ou remova o anexo na seção 1 antes de finalizar.'
    );
  });

  // ---- Prefill dos dados do aluno (seção 1) — a turma é fixa (perfil selecionado) ----
  // Zera os campos da seção 1 e esconde os avisos do aluno (usado no branch vazio, antes da
  // requisição e no erro — para não deixar dado do aluno anterior rotulado como do novo).
  function clearStudentSection1() {
    $('.iep-birth-date, .iep-guardians, .iep-diagnosis, .iep-shift').val('');
    $('.iep-guardians-warning').hide();
    $('.iep-existing-plan-warning').hide();
  }

  function fetchStudentData(studentId) {
    var $warning = $('.iep-existing-plan-warning');

    // Limpa o erro de duplicidade do submit anterior: remove a classe .error do
    // .control-group (tira a borda vermelha do select2) e a mensagem.
    var $wrapper = $studentSelect.closest('.control-group');
    $wrapper.removeClass('error');
    $wrapper.find('span.help-inline, .help-inline.error, span.error').remove();

    if (!studentId || studentId === 'empty') {
      // Sem aluno (limpo manualmente ou ao trocar a data de elaboração): zera a seção 1.
      clearStudentSection1();
      medicalReportsMessage($medicalReports.data('pending-text'));
      return;
    }

    var params = { student_id: studentId, format: 'json' };
    var planId = $wizard.data('plan-id');
    if (planId) { params.plan_id = planId; }
    // Mesma data do select: valida o aluno contra a enturmação da data de elaboração (não hoje).
    var elaboratedAt = $('.iep-elaborated-at').val();
    if (elaboratedAt) { params.elaborated_at = elaboratedAt; }

    // Limpa os campos ANTES da requisição: numa falha (sessão expirada, sem permissão,
    // timeout), o error handler abaixo assume — sem isso, os campos ficariam com o
    // dado do aluno anterior rotulado como sendo do aluno recém-selecionado.
    clearStudentSection1();

    $.ajax({
      url: Routes.student_data_individualized_educational_plans_pt_br_path(params),
      dataType: 'json',
      success: function(data) {
        $('.iep-birth-date').val(data.birth_date || '');
        $('.iep-guardians').val(data.guardians || '');
        $('.iep-diagnosis').val(data.diagnosis || '');
        $('.iep-shift').val(data.shift || '');
        $('.iep-guardians-warning').toggle(!!data.guardians_unavailable);
        // Os laudos vêm na MESMA resposta (mesma consulta ao i-Educar): renderiza daqui em
        // vez de fazer uma segunda chamada. A identidade é o studentId desta requisição.
        renderMedicalReports(data.medical_reports, data.medical_reports_unavailable,
                             medicalReportIdentity(studentId));
        // Aviso antecipado: aluno já tem PEI neste ano letivo (antes de preencher/finalizar)
        $warning.toggle(!!data.has_existing_plan);
      },
      error: function(jqXHR) {
        clearStudentSection1();
        renderMedicalReports([], true, medicalReportIdentity(studentId));
        flashMessages.error(
          jqXHR && jqXHR.status === 403
            ? 'Este aluno já possui um PEI que você acessa somente em leitura. Abra o plano pela listagem.'
            : 'Ocorreu um erro ao buscar os dados do aluno selecionado.'
        );
      }
    });
  }

  $studentSelect.on('change', function() {
    clearMedicalReportError();
    discardPendingUploadsOnStudentChange();
    if (studentFetchEnabled) { fetchStudentData($(this).val()); }
  });

  // Aluno já selecionado ao abrir a tela (edição, ou reabertura após erro de validação):
  // busca os dados via AJAX, já que "Responsáveis" não vem preenchido do servidor. Na edição
  // o select2 popula as options só DEPOIS deste código (o select ainda está vazio aqui), então
  // o valor confiável do aluno é o hidden renderizado pelo servidor.
  var initialStudentId = $studentSelect.val() || $('input[type="hidden"][name$="[student_id]"]').val();
  if (studentFetchEnabled && initialStudentId && initialStudentId !== 'empty') {
    fetchStudentData(initialStudentId);
  } else {
    // Versão publicada (ou tela sem aluno ainda): o prefill não roda, mas o laudo é buscado
    // sempre que há plano ou aluno — ele não faz parte do que a versão congela.
    fetchMedicalReports();
  }

  // ---- Criação: a data de elaboração filtra os alunos ----
  // O usuário escolhe a data primeiro; o select passa a listar só quem estava enturmado na turma
  // do perfil NAQUELA data. No editar/visualizar o aluno é fixo (select desabilitado) → não roda.
  var $elaboratedAt = $('.iep-elaborated-at');

  // Repopula o select2 pelo destroy + re-init com data (mesmo idioma do index.js). Trocar as
  // <option> do select nativo direto quebra o widget do select2 (vira uma lista solta).
  function setStudentOptions(students) {
    var studentOptions = $.map(students, function(student) {
      return { id: student.id, name: student.name, text: student.name };
    });
    studentOptions.unshift({ id: 'empty', name: '', text: '' });

    $studentSelect.select2('destroy');
    $studentSelect.select2({
      data: studentOptions,
      // _.escape: o nome vem do endpoint e não é confiável para interpolar como HTML.
      formatResult: function(el) { return "<div class='select2-user-result'>" + _.escape(el.name) + "</div>"; },
      formatSelection: function(el) {
        return "<div class='select2-user-result'>" + _.escape(el.text || el.name) + "</div>";
      },
      allowClear: true,
      theme: 'classic'
    });
    $studentSelect.select2('val', '');
    discardPendingUploadsOnStudentChange();
    fetchStudentData('');
  }

  // Aviso de data fora do calendário letivo (o bloqueio real é no servidor ao salvar).
  function setElaborationCalendarWarning(message) {
    var $group = $elaboratedAt.closest('.control-group');
    $group.find('.iep-posting-warning').remove();
    if (message) {
      $('<span class="help-inline error iep-posting-warning"></span>').text(message).insertAfter($elaboratedAt);
    }
  }

  var studentsXhr = null;

  function reloadStudentsForElaborationDate(dateStr) {
    if (studentsXhr) { studentsXhr.abort(); }

    studentsXhr = $.ajax({
      url: Routes.students_by_elaboration_date_individualized_educational_plans_pt_br_path(
        { elaborated_at: dateStr, format: 'json' }
      ),
      dataType: 'json',
      success: function(data) {
        if (data && Array.isArray(data.students)) { setStudentOptions(data.students); }
        setElaborationCalendarWarning(data && data.calendar_error);
      },
      error: function(jqXHR, textStatus) {
        // A requisição abortada acima também cai aqui: é substituição, não falha.
        if (textStatus === 'abort') { return; }

        setStudentOptions([]);
        setElaborationCalendarWarning('');
        flashMessages.error('Não foi possível atualizar a lista de alunos para a data de elaboração.');
      },
      complete: function(jqXHR) {
        if (studentsXhr === jqXHR) { studentsXhr = null; }
      }
    });
  }

  if ($elaboratedAt.length && !$studentSelect.prop('disabled')) {
    $elaboratedAt.on('change', function() {
      var value = $(this).val();

      // Data inválida (isValidDate global, date.js): não consulta o servidor e limpa só o aviso
      // de calendário — o vermelho de "data válida" fica por conta do validador de data do form.
      if (!isValidDate(value)) {
        setElaborationCalendarWarning('');
        return;
      }

      reloadStudentsForElaborationDate(value);
    });
  }

  // ---- Finalizar: o modal "Salvar versão" preenche version_name e submete o próprio form ----
  var finalizeConfirmed = false;

  var MIN_VERSION_NAME = 3;

  function clearVersionNameError() {
    $('#version_name').closest('.input').removeClass('state-error');
    $('.iep-version-name-error').hide();
  }

  $('#iep-finalize-confirm').on('click', function() {
    var $name = $('#version_name');

    if (($name.val() || '').trim().length < MIN_VERSION_NAME) {
      $name.closest('.input').addClass('state-error');
      $('.iep-version-name-error').show();
      $name.focus();
      return;
    }

    clearVersionNameError();
    finalizeConfirmed = true;
    $(this).prop('disabled', true);
    $('.smart-form').submit();
  });

  $('#version_name').on('input', function() {
    if ($(this).val().trim().length >= MIN_VERSION_NAME) { clearVersionNameError(); }
  });

  // Fechou o modal sem confirmar: limpa o nome e o estado de erro
  $('#iep-finalize-modal').on('hidden.bs.modal', function() {
    if (!finalizeConfirmed) {
      $('#version_name').val('');
      clearVersionNameError();
    }
  });

  // ---- Seções 4/5: botões de revisão mostram o painel da revisão ----
  $('.iep-review-buttons button').on('click', function() {
    var reviewId = $(this).data('review-id');
    var $fieldset = $(this).closest('fieldset');

    $(this).siblings().removeClass('active btn-primary').addClass('btn-default');
    $(this).addClass('active btn-primary').removeClass('btn-default');

    $fieldset.find('.iep-review-panel').hide()
      .filter('[data-review-id="' + reviewId + '"]').show();
  });

  // ---- Seções 4/5: pills de componente mostram o form do componente (pills são dinâmicas) ----
  $(document).on('click', '.iep-component-pills a', function() {
    var targetKey = String($(this).data('target-key'));
    var $tabPane = $(this).closest('.tab-pane');

    $(this).closest('ul').find('li').removeClass('active');
    $(this).closest('li').addClass('active');

    $tabPane.find('.iep-component-panel').hide()
      .filter(function() { return String($(this).data('key')) === targetKey; }).show();
  });

  // ---- Seções 4/5: adição de componente sob demanda (modal) ----
  var $componentModal = $('#iep-component-modal');
  var $componentModalSelect = $('#iep-component-modal-select');
  var pendingAdd = null;
  var newComponentKey = 0;

  function usedComponentIds($panels) {
    var field = $panels.data('component-type') + '_id';

    return $panels.find('.iep-component-panel')
      .filter(function() {
        var destroy = $(this).find('input[name$="[_destroy]"]').val();
        return destroy !== '1' && destroy !== 'true'; // ignora os removidos (cocoon só os esconde)
      })
      .map(function() { return $(this).find('input[name$="[' + field + ']"]').val(); })
      .get().filter(Boolean).map(String);
  }

  $(document).on('click', '.iep-add-component', function() {
    var $panels = $($(this).data('panels'));
    var componentType = $panels.data('component-type');
    var elements = componentType === 'discipline' ? $componentModal.data('disciplines') : $componentModal.data('knowledge-areas');
    var used = usedComponentIds($panels);
    var available = elements.filter(function(element) { return used.indexOf(String(element.id)) === -1; });

    pendingAdd = { $panels: $panels, componentType: componentType };

    var $modalTitle = $componentModal.find('.modal-title');
    $modalTitle.text(
      componentType === 'discipline' ? $modalTitle.data('title-discipline')
                                     : $modalTitle.data('title-knowledge-area')
    );

    if ($componentModalSelect.data('select2')) { $componentModalSelect.select2('destroy'); }
    $componentModalSelect.val('');
    $componentModalSelect.select2({ data: available, allowClear: false, theme: 'classic' });

    $componentModal.modal('show');
  });

  $('#iep-component-modal-confirm').on('click', function() {
    var selected = $componentModalSelect.select2('data');
    if (!selected || !pendingAdd) { return; }

    pendingAdd.component = selected;
    pendingAdd.$panels.closest('.tab-pane').find('.iep-add-line').trigger('click'); // cocoon insere o form
    $componentModal.modal('hide');
  });

  // Form inserido pelo cocoon: vincula à revisão/componente escolhidos e ganha a pill
  $(document).on('cocoon:after-insert', '.iep-component-panels', function(event, insertedItem) {
    if (!pendingAdd || !pendingAdd.component) { return; }

    var $panels = pendingAdd.$panels;
    var field = pendingAdd.componentType + '_id';

    // O cocoon insere todo componente novo com o mesmo data-key literal ("new_<assoc>"),
    // então geramos uma chave única aqui para o painel e a pill não colidirem entre si.
    var uniqueKey = 'new_component_' + (newComponentKey += 1);
    insertedItem.attr('data-key', uniqueKey);

    insertedItem.find('input[name$="[iep_review_date_id]"]').val($panels.data('review-id'));
    insertedItem.find('input[name$="[' + field + ']"]').val(pendingAdd.component.id);
    insertedItem.find('.iep-component-title').text(pendingAdd.component.text);

    var $pills = $panels.closest('.tab-pane').find('.iep-component-pills');
    $pills.find('li').removeClass('active');
    $pills.append(
      $('<li class="active"><a href="javascript:void(0)"></a></li>')
        .find('a').text(pendingAdd.component.text).attr('data-target-key', uniqueKey).end()
    );

    $panels.find('.iep-component-panel').hide();
    insertedItem.show();

    pendingAdd = null;
  });

  // Form removido (lixeira): remove a pill correspondente e ativa a primeira restante
  $(document).on('cocoon:after-remove', '.iep-component-panels', function(event, removedItem) {
    var $tabPane = $(this).closest('.tab-pane');
    var key = String(removedItem.data('key'));
    var $pills = $tabPane.find('.iep-component-pills');

    $pills.find('a').filter(function() { return String($(this).data('target-key')) === key; }).closest('li').remove();

    var $firstPill = $pills.find('a').first();
    if ($firstPill.length) { $firstPill.trigger('click'); }
  });
});
