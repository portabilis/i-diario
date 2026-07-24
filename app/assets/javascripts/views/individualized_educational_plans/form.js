$(function() {
  'use strict';

  var $wizard = $('#pei-wizard');
  if ($wizard.length === 0) { return; }

  var flashMessages = new FlashMessages();

  // Etapas do topo do wizard (fuelux steps); os painéis top-level ficam em .tab-content direto do wizard
  var $steps = $wizard.find('.fuelux .steps li');
  var $panes = $wizard.children('.tab-content').children('.tab-pane');
  var $studentSelect = $('.iep-student-select');

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

  // ---- Prefill dos dados do aluno (seção 1) — a turma é fixa (perfil selecionado) ----
  function fetchStudentData(studentId) {
    var $warning = $('.iep-existing-plan-warning');

    // Limpa o erro de duplicidade do submit anterior: remove a classe .error do
    // .control-group (tira a borda vermelha do select2) e a mensagem.
    var $wrapper = $studentSelect.closest('.control-group');
    $wrapper.removeClass('error');
    $wrapper.find('span.help-inline, .help-inline.error, span.error').remove();

    if (!studentId || studentId === 'empty') { $warning.hide(); return; }

    var params = { student_id: studentId, format: 'json' };
    var planId = $studentSelect.data('plan-id');
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
        // Aviso antecipado: aluno já tem PEI neste ano letivo (antes de preencher/finalizar)
        $warning.toggle(!!data.has_existing_plan);
      },
      error: function() {
        $('.iep-birth-date, .iep-guardians, .iep-diagnosis, .iep-shift').val('');
        $('.iep-guardians-warning').hide();
        $warning.hide();
        flashMessages.error('Ocorreu um erro ao buscar os dados do aluno selecionado.');
      }
    });
  }

  $studentSelect.on('change', function() { fetchStudentData($(this).val()); });

  // Aluno já selecionado ao abrir a tela (edição, ou reabertura após erro de validação):
  // busca os dados via AJAX, já que "Responsáveis" não vem preenchido do servidor.
  if ($studentSelect.val() && $studentSelect.val() !== 'empty') {
    fetchStudentData($studentSelect.val());
  }

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
