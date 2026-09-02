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

    $pendingLink = $(this);
    $modal.modal('show');
  });

  $modal.on('click', '#last-step-absence-warning-continue', function () {
    var $link = $pendingLink;
    $pendingLink = null;

    $modal.modal('hide');

    if ($link) $.rails.handleMethod($link);
  });

  $modal.on('hidden.bs.modal', function () {
    $pendingLink = null;
  });
});
