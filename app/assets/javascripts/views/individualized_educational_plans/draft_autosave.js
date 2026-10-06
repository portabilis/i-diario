// Salvamento de rascunho do PEI a cada troca de etapa do wizard.
//
// O formulário inteiro é enviado por AJAX para o create/update com draft=1; o servidor grava sem
// publicar versão e devolve o formulário re-renderizado. Daqui só as regiões com registros filhos
// são trocadas na tela: é o que traz os ids dos filhos recém-criados (sem isso o envio seguinte os
// criaria de novo) e o que faz as revisões da seção 1 aparecerem nas seções 4 e 5.
//
// options:
//   $form, $wizard
//   showStep(index)         - troca a etapa visível
//   readyToCreate()         - true quando há aluno e data de elaboração para criar o plano
//   rehydrate($region)      - religa os widgets de uma região recém-trocada
//   onCreated(data)         - o plano acabou de ser criado (data.id, data.update_url, data.edit_url)
//   onUnavailable()         - o servidor recusou o rascunho para este aluno (só grava ao finalizar)
//   failureMessage(jqXHR, textStatus) - mensagem para falha de sessão/permissão, ou null
window.IepDraftAutosave = function(options) {
  'use strict';

  var $form = options.$form;
  var $wizard = options.$wizard;
  var $status = $form.find('.iep-save-status');
  var $statusText = $status.find('.iep-save-status-text');
  var $alert = $form.find('.iep-save-error');
  var $alertText = $alert.find('.iep-save-error-text');
  var $retry = $form.find('.iep-save-retry');

  // Sempre o conteúdo, nunca o elemento: o form.js guarda referência a estes nós e tem handlers
  // presos neles.
  var REGIONS = ['#iep-review-dates', '#iep-medications', '#pei-step-4 > fieldset', '#pei-step-5 > fieldset'];
  var SECTION_PANES = ['#pei-step-4', '#pei-step-5'];
  var LINE_PANEL = '.iep-component-panel';
  var LINE_BASELINE = 'iepDraftBaseline';
  var IGNORED_NAMES = ['utf8', 'authenticity_token', '_method', 'version_name'];
  var PARAM = 'individualized_educational_plan';
  var FIELD_ERROR = 'iep-draft-field-error';
  var NAVIGATION = '.pei-wizard-next, .pei-wizard-prev, .pei-wizard-finish';

  var enabled = $wizard.data('autosave') === 'on';
  var busy = false;
  var baseline = null;

  function hasPlan() {
    return !!$wizard.data('plan-id');
  }

  // Só o que o usuário pode alterar: campo readonly ou desabilitado fica de fora. Isso exclui os
  // campos de exibição da seção 1, que o prefill do i-Educar preenche depois da carga da página
  // e que, se contassem, fariam o formulário parecer alterado sem o usuário ter digitado nada.
  function formSignature() {
    return $form.find(':input[name]').filter(function() {
      return !this.readOnly && !this.disabled && IGNORED_NAMES.indexOf(this.name) === -1;
    }).serialize();
  }

  function lineSignature($panel) {
    return $panel.find(':input').serialize();
  }

  // Prefixo do name que identifica um registro aninhado: "...[assoc_attributes][chave]".
  function nestedPrefix(name) {
    var match = (name || '').match(/^(.+?_attributes\]\[[^\]]+\])/);

    return match ? match[1] : null;
  }

  function nestedInput(prefix, field) {
    return prefix ? $form.find('input[name="' + prefix + '[' + field + ']"]') : $();
  }

  // O hidden de id de uma linha salva é emitido pelo fields_for fora do painel dela; é achado
  // pelo prefixo do name dos campos da linha.
  function lineIdInput($panel) {
    return nestedInput(nestedPrefix($panel.find(':input[name]').first().attr('name')), 'id');
  }

  function markBaseline() {
    baseline = formSignature();
    $form.find(LINE_PANEL).each(function() {
      $(this).data(LINE_BASELINE, lineSignature($(this)));
    });
  }

  // Campos das linhas das seções 4/5 que não mudaram desde a carga. Ficam fora do envio para que
  // a cópia da tela, possivelmente desatualizada, não sobrescreva o que outro usuário gravou
  // nessas linhas. Linha nova não tem estado de carga e por isso sempre é enviada.
  function unchangedLineInputs() {
    var $inputs = $();

    $form.find(LINE_PANEL).each(function() {
      var $panel = $(this);
      var loaded = $panel.data(LINE_BASELINE);

      if (loaded === undefined || loaded !== lineSignature($panel)) { return; }

      $inputs = $inputs.add($panel.find(':input')).add(lineIdInput($panel));
    });

    return $inputs;
  }

  function payload() {
    var fields = $form.find(':input').not(unchangedLineInputs()).filter(function() {
      return this.name !== 'version_name';
    }).serializeArray();

    fields.push({ name: 'draft', value: '1' });

    return $.param(fields);
  }

  // ---- Indicador de salvamento ----
  // O andamento e o sucesso ficam no rodapé. A falha também aparece num alerta no topo da etapa,
  // com o motivo: o rodapé fica fora da tela para quem troca de etapa pelo título, lá em cima.
  function setStatus(text) {
    $status.removeClass('iep-save-failed');
    $statusText.text(text || '');
    $alert.hide();
    $retry.hide();
    clearFieldErrors();
  }

  // ---- Destaque do campo recusado, com a mesma marcação que o simple_form usa no erro ----
  function clearFieldErrors() {
    $form.find('.' + FIELD_ERROR).removeClass('error ' + FIELD_ERROR)
      .find('.' + FIELD_ERROR + '-message').remove();
  }

  // Campos do formulário a que o erro se refere. Registro aninhado gravado é achado pelo id;
  // o que ainda não foi gravado não tem como ser identificado, então valem as linhas novas, não
  // removidas, em que o campo está vazio.
  function fieldErrorInputs(fieldError) {
    if (!fieldError.association) {
      return $form.find(':input[name="' + PARAM + '[' + fieldError.attribute + ']"]');
    }

    var start = PARAM + '[' + fieldError.association + '_attributes][';
    var end = '][' + fieldError.attribute + ']';

    return $form.find(':input[name]').filter(function() {
      var name = this.name;
      if (name.indexOf(start) !== 0 || name.slice(-end.length) !== end) { return false; }

      var prefix = nestedPrefix(name);
      var destroy = nestedInput(prefix, '_destroy').val();
      if (destroy === '1' || destroy === 'true') { return false; }

      var id = nestedInput(prefix, 'id').val();

      return fieldError.id ? String(id) === String(fieldError.id) : !id && $.trim($(this).val()) === '';
    });
  }

  function showFieldErrors(fieldErrors) {
    $.each(fieldErrors || [], function(_index, fieldError) {
      fieldErrorInputs(fieldError).each(function() {
        var $group = $(this).closest('.control-group');
        if ($group.length === 0 || $group.hasClass('error')) { return; }

        $group.addClass('error ' + FIELD_ERROR);
        // Campo que já mostra uma mensagem (o aviso de calendário da data de elaboração, por
        // exemplo) não ganha uma segunda: uma por campo, como no simple_form.
        if ($group.find('.help-inline').length) { return; }

        $group.append($('<span class="help-inline">').addClass(FIELD_ERROR + '-message').text(fieldError.message));
      });
    });

    // Como na finalização: se o campo recusado está em outra etapa, é ela que abre.
    var $panes = $wizard.children('.tab-content').children('.tab-pane');
    var $withError = $panes.has('.' + FIELD_ERROR);

    if ($withError.length && !$withError.is('.active')) { options.showStep($panes.index($withError.first())); }
  }

  function showFailure(message, retryable) {
    $status.addClass('iep-save-failed');
    $statusText.text($status.data('failed-text'));
    $alertText.text(message);
    $alert.show();
    $retry.toggle(!!retryable);

    if ($alert.length && $alert[0].scrollIntoView) { $alert[0].scrollIntoView({ block: 'center' }); }
  }

  function currentTime() {
    var now = new Date();
    var pad = function(value) { return (value < 10 ? '0' : '') + value; };

    return pad(now.getHours()) + ':' + pad(now.getMinutes());
  }

  function showSaved() {
    setStatus($status.data('saved-text') + ' ' + currentTime() + ' - ' + $status.data('unpublished-text'));
  }

  function showRefused(body) {
    showFailure((body.errors || []).join(' '), false);
    showFieldErrors(body.field_errors);

    if (body.existing_plan_url) {
      $alertText.append(' ').append(
        $('<a class="btn btn-default btn-sm">').attr('href', body.existing_plan_url)
          .text($status.data('existing-plan-text') + ' ').append('<i class="fa fa-arrow-right"></i>')
      );
    }
  }

  // ---- Seções 4/5: o que estava aberto antes da troca volta a ficar aberto ----
  function reviewPanel($pane, reviewId) {
    return $pane.find('.iep-review-panel').filter(function() {
      return String($(this).data('review-id')) === String(reviewId);
    });
  }

  function captureSections() {
    return $.map(SECTION_PANES, function(selector) {
      var $pane = $form.find(selector);
      var reviewId = $pane.find('.iep-review-buttons button.active').data('review-id');
      var $panel = reviewPanel($pane, reviewId);
      var tabHref = $panel.find('.nav-tabs li.active a').attr('href');

      return {
        pane: selector,
        reviewId: reviewId,
        tabHref: tabHref,
        // Texto e não data-key: a linha criada nesta sessão volta do servidor com outra chave.
        pill: tabHref ? $.trim($panel.find(tabHref + ' .iep-component-pills li.active a').text()) : ''
      };
    });
  }

  function restoreSections(states) {
    $.each(states, function(_index, state) {
      if (state.reviewId === undefined) { return; }

      var $pane = $form.find(state.pane);

      $pane.find('.iep-review-buttons button').filter(function() {
        return String($(this).data('review-id')) === String(state.reviewId);
      }).trigger('click');

      if (!state.tabHref) { return; }

      var $tab = $pane.find('.nav-tabs a[href="' + state.tabHref + '"]');
      if ($tab.length && $.fn.tab) { $tab.tab('show'); }

      $pane.find(state.tabHref + ' .iep-component-pills a').filter(function() {
        return $.trim($(this).text()) === state.pill;
      }).first().trigger('click');
    });
  }

  function swapRegions(html) {
    var $fresh = $('<div>').append($.parseHTML(html, document, false));
    var sections = captureSections();

    $.each(REGIONS, function(_index, selector) {
      var $target = $form.find(selector);
      var $source = $fresh.find(selector);

      if ($target.length === 0 || $source.length === 0) { return; }

      $target.empty().append($source.contents());
      options.rehydrate($target);
    });

    restoreSections(sections);
  }

  // ---- Envio ----
  function responseBody(jqXHR) {
    if (jqXHR.responseJSON) { return jqXHR.responseJSON; }

    try {
      return JSON.parse(jqXHR.responseText);
    } catch (error) {
      return null;
    }
  }

  // Resolve quando gravou. Rejeita com o motivo:
  //   'unavailable' - o rascunho não se aplica a este aluno; dali em diante nada é enviado
  //   'refused'     - o servidor recusou os dados (validação, permissão, plano já existente)
  //   'failed'      - a requisição não completou (rede, sessão expirada, erro do servidor)
  function save() {
    var result = $.Deferred();
    var creating = !hasPlan();

    setStatus($status.data('saving-text'));

    $.ajax({
      url: $form.attr('action'),
      type: 'POST',
      data: payload(),
      dataType: 'json',
      headers: { 'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content') }
    }).done(function(data) {
      if (!data || !data.id || typeof data.form_html !== 'string') {
        showFailure($status.data('failed-text'), true);
        result.reject('failed');
        return;
      }

      if (creating) { options.onCreated(data); }

      swapRegions(data.form_html);
      markBaseline();
      showSaved();
      result.resolve();
    }).fail(function(jqXHR, textStatus) {
      var body = responseBody(jqXHR);

      if (body && body.draft_unavailable) {
        enabled = false;
        setStatus('');
        options.onUnavailable();
        result.reject('unavailable');
      } else if (body && body.errors) {
        showRefused(body);
        result.reject('refused');
      } else {
        showFailure(options.failureMessage(jqXHR, textStatus) || $status.data('failed-text'), true);
        result.reject('failed');
      }
    });

    return result.promise();
  }

  function shouldSave() {
    if (!enabled) { return false; }

    return hasPlan() ? formSignature() !== baseline : options.readyToCreate();
  }

  function run(afterSaved, afterRejected) {
    busy = true;
    $(NAVIGATION).prop('disabled', true);

    save().done(afterSaved).fail(afterRejected).always(function() {
      busy = false;
      $(NAVIGATION).prop('disabled', false);
    });
  }

  // Salva e só então troca de etapa: a etapa de destino já abre com as regiões atualizadas e
  // nada é digitado nela enquanto a resposta não chega.
  function saveThenGo(index) {
    if (busy) { return; }

    if (!shouldSave()) {
      // Nada pendente: a falha de um envio anterior já não descreve o que está na tela.
      if ($status.hasClass('iep-save-failed')) { setStatus(''); }
      options.showStep(index);
      return;
    }

    run(
      function() { options.showStep(index); },
      function(reason) {
        // Dados recusados: fica na etapa, onde está o que precisa ser corrigido. Falha de
        // requisição com o plano ainda por criar também fica: as demais etapas estão travadas.
        if (reason === 'unavailable' || (reason === 'failed' && hasPlan())) { options.showStep(index); }
      }
    );
  }

  // Campo destacado que o usuário voltou a editar deixa de ficar em vermelho.
  $form.on('input change', '.' + FIELD_ERROR + ' :input', function() {
    $(this).closest('.' + FIELD_ERROR).removeClass('error ' + FIELD_ERROR)
      .find('.' + FIELD_ERROR + '-message').remove();
  });

  $retry.on('click', function() {
    if (busy || !shouldSave()) { return; }

    run($.noop, $.noop);
  });

  return {
    saveThenGo: saveThenGo,
    markBaseline: markBaseline,
    // Sem plano gravado as etapas 2 a 6 não podem ser preenchidas.
    isLocked: function() { return enabled && !hasPlan(); },
    // Envio nativo do formulário (finalização): as linhas inalteradas das seções 4/5 também
    // ficam de fora, pelo mesmo motivo do rascunho.
    disableUnchangedLines: function() { unchangedLineInputs().prop('disabled', true); }
  };
};
