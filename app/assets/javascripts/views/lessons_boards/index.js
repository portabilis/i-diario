// Recria um filtro da tela com as opções e o valor que o servidor devolve (ver index.js.erb).
// Usa o initSelect2 global para estes campos não divergirem dos demais select2 do sistema.
window.lessonsBoardsIndex = {
  refreshFilter: function (fieldId, elements, value) {
    // As três chamadas rodam no mesmo script: uma exceção aqui deixaria os outros filtros com
    // opções antigas e sem sinal.
    try {
      var $field = $('#' + fieldId);

      if ($field.length === 0) {
        // O servidor só chama refreshFilter para um filtro que acabou de renderizar, então campo
        // ausente é defeito.
        console.warn('lessonsBoardsIndex: filtro não encontrado na página: #' + fieldId);
        return;
      }

      // O select2 não recarrega `data` de um campo já inicializado.
      if ($field.data('select2')) { $field.select2('destroy'); }

      $field.data('elements', elements);

      // `val` puro, sem disparar change: o handler do filterable_search_form refaz a busca a cada
      // change e entraria em loop.
      $field.val(value);

      window.initSelect2($field);
    } catch (error) {
      console.error('lessonsBoardsIndex: falha ao recriar o filtro #' + fieldId, error);
    }
  }
};

$(function () {
  var flashMessages = new FlashMessages();

  // Quando a requisição remota falha nada é reescrito e a tela segue exibindo o resultado
  // anterior como se fosse o novo. O handler mora no arquivo desta tela, então o aviso vale só
  // para o quadro de aulas.
  $(document).ajaxError(function (event, jqxhr) {
    if (jqxhr && jqxhr.statusText === 'abort') { return; }

    flashMessages.error(
      'Não foi possível atualizar a listagem. Verifique sua conexão e tente novamente.'
    );
  });
});
