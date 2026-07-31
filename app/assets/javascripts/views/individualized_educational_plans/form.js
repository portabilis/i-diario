$(function() {
  'use strict';

  var $wizard = $('#pei-wizard');
  if ($wizard.length === 0) { return; }

  var flashMessages = new FlashMessages();

  // Etapas do topo do wizard (fuelux steps); os painéis top-level ficam em .tab-content direto do wizard
  var $steps = $wizard.find('.fuelux .steps li');
  var $panes = $wizard.children('.tab-content').children('.tab-pane');
  var $studentSelect = $('.iep-student-select');
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

    return { student_id: studentId };
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

  function medicalReportsErrorMessage(jqXHR, textStatus) {
    var status = jqXHR && jqXHR.status;

    if (status === 401 || status === 403 || textStatus === 'parsererror') {
      return 'Sua sessão expirou ou você não tem acesso a este plano. Recarregue a página e tente novamente.';
    }

    return 'Não foi possível consultar os laudos no i-Educar.';
  }

  // ---- Prefill dos dados do aluno (seção 1) — a turma é fixa (perfil selecionado) ----
  function fetchStudentData(studentId) {
    var $warning = $('.iep-existing-plan-warning');

    // Limpa o erro de duplicidade do submit anterior: remove a classe .error do
    // .control-group (tira a borda vermelha do select2) e a mensagem.
    var $wrapper = $studentSelect.closest('.control-group');
    $wrapper.removeClass('error');
    $wrapper.find('span.help-inline, .help-inline.error, span.error').remove();

    if (!studentId || studentId === 'empty') {
      $warning.hide();
      medicalReportsMessage($medicalReports.data('pending-text'));
      return;
    }

    var params = { student_id: studentId, format: 'json' };
    var planId = $wizard.data('plan-id');
    if (planId) { params.plan_id = planId; }

    // Limpa os campos ANTES da requisição: numa falha (sessão expirada, sem permissão,
    // timeout), o error handler abaixo assume — sem isso, os campos ficariam com o
    // dado do aluno anterior rotulado como sendo do aluno recém-selecionado.
    $('.iep-birth-date, .iep-guardians, .iep-diagnosis, .iep-shift').val('');
    $('.iep-guardians-warning').hide();
    $warning.hide();

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
      error: function() {
        $('.iep-birth-date, .iep-guardians, .iep-diagnosis, .iep-shift').val('');
        $('.iep-guardians-warning').hide();
        renderMedicalReports([], true, medicalReportIdentity(studentId));
        $warning.hide();
        flashMessages.error('Ocorreu um erro ao buscar os dados do aluno selecionado.');
      }
    });
  }

  $studentSelect.on('change', function() {
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
