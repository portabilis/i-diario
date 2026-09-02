// Intercepta os links `method: post` das faltas da última etapa e só dispara o POST
// (pelo mesmo caminho do jquery_ujs) depois que o usuário confirma na modal.
$(function () {
  var $modal = $('#last-step-absence-warning-modal');
  if (!$modal.length) return;

  var $pendingLink = null;

  // Handler direto no elemento: roda antes do delegate do jquery_ujs em `document` e do
  // listener nativo do force_posting.js. O stopImmediatePropagation do jQuery 1.x não chega
  // ao evento nativo, então o listener nativo precisa ser barrado pelo originalEvent.
  $('a[data-last-step-absence-warning]').on('click', function (event) {
    event.preventDefault();
    event.stopImmediatePropagation();
    if (event.originalEvent) event.originalEvent.stopImmediatePropagation();

    // Link já enviado: o disableElement do ujs guarda o estado anterior em `ujs:enable-with` e
    // barra novos cliques por um handler próprio. Como este aqui roda antes dele e interrompe a
    // fila, a marca precisa ser respeitada aqui também — senão a modal reabre e envia de novo.
    if ($(this).data('ujs:enable-with') !== undefined) return;

    $pendingLink = $(this);
    $modal.modal('show');
  });

  $modal.on('click', '#last-step-absence-warning-continue', function () {
    var $link = $pendingLink;
    $pendingLink = null;

    $modal.modal('hide');

    if (!$link) return;

    // O "Repetir envio" com aviso troca o onclick inline por data-resend-*: o marcador de
    // cooldown do force_posting.js só pode valer para um envio que de fato acontece.
    // O índice pode ser 0, então a ausência se testa por undefined, não por falsy.
    if ($link.data('resend-index') !== undefined) {
      resend_posting($link.data('resend-index'), $link.data('resend-step-id'));
    }

    // Quem aplica o data-disable-with é o handler de clique do jquery_ujs, que a interceptação
    // pula; handleMethod só monta e submete o form. Sem esta linha o botão não vira "Enviando..."
    // e continua aceitando um segundo envio.
    if ($link.is($.rails.linkDisableSelector)) $.rails.disableElement($link);

    $.rails.handleMethod($link);
  });

  $modal.on('hidden.bs.modal', function () {
    $pendingLink = null;
  });
});
