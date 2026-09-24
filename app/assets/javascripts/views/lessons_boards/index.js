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

  function pathOf(url) {
    var link = document.createElement('a');

    link.href = url || '';

    return link.pathname;
  }

  // Quando a requisição que atualiza a listagem falha, nada na tela é reescrito e o resultado
  // anterior continua exibido como se fosse o do filtro recém-aplicado.
  //
  // O aviso é restrito ao endereço da própria listagem: o evento de erro do jQuery é disparado por
  // qualquer requisição da página, e anunciar falha de listagem quando quem falhou foi outra coisa
  // — as notificações, por exemplo — aponta o usuário para o lugar errado.
  $(document).ajaxError(function (event, jqxhr, settings) {
    if (jqxhr && jqxhr.statusText === 'abort') { return; }
    if (!settings) { return; }
    if (pathOf(settings.url) !== pathOf($('form.filterable_search_form').attr('action'))) { return; }

    flashMessages.error(
      'Não foi possível atualizar a lista de quadros de aula. Verifique sua conexão e tente novamente.'
    );
  });
});
