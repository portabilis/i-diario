// Recria um filtro da tela quando o servidor devolve as opções da cascata (ver index.js.erb).
// A cascata é resolvida no servidor: ele manda as opções válidas e o valor já saneado de cada
// filtro, então aqui só resta reconstruir o select2 — reusando o initSelect2 global para que estes
// campos não divirjam dos demais select2 do sistema.
window.lessonsBoardsIndex = {
  refreshFilter: function (fieldId, elements, value) {
    var $field = $('#' + fieldId);

    if ($field.length === 0) { return; }

    // O select2 v3 não recarrega `data` de um campo já inicializado, por isso o destroy.
    if ($field.data('select2')) { $field.select2('destroy'); }

    $field.data('elements', elements);

    // `val` puro, sem disparar change: o handler global do filterable_search_form refaz a busca a
    // cada change e entraria em loop de requisições.
    $field.val(value);

    window.initSelect2($field);
  }
};
