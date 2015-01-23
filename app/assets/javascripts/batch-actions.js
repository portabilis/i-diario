$(function () {
  $('a#destroy-batch').on('click', function (e) {
    e.preventDefault();

    var table = $('#resources tbody');
        url = $(this).attr('href'),
        checkboxes = table.find('input.select-target:checked'),
        ids = _.map(checkboxes, function (el) { return $(el).val() });

    if (checkboxes.length == 0) {
      alert("Selecione um registro primeiro.");
    } else {
      if (confirm("Confirmar?")) {
        var jhr = $.ajax({
          url: url,
          type: 'DELETE',
          dataType: "script",
          data: { ids: ids }
        });

        jhr.success(function () {
          _.each(ids, function (id) {
            table.find("tr[id$=_" + id +"]").remove();
          });

          $('#flash-messages').html('<div class="alert alert-success fade in"><i class="fa-fw fa fa-check"></i>Registros apagados com sucesso!!</div>');
        });

        jhr.error(function (jqXHR, textStatus, errorThrown) {
          $('#flash-messages').html('<div class="alert alert-danger fade in"><i class="fa-fw fa fa-times"></i>Os registros não foram excluídos. Verifique se os mesmos possuem vínculos com outras funcionalidades antes de excluir.</div>');
        });
      }
    }
  });

  $('a#activate-batch').on('click', function (e) {
    e.preventDefault();

    var table = $('#resources tbody');
        url = $(this).attr('href'),
        checkboxes = table.find('input.select-target:checked'),
        ids = _.map(checkboxes, function (el) { return $(el).val() });

    if (checkboxes.length == 0) {
      alert("Selecione um registro primeiro.");
    } else {
      if (confirm("Confirmar?")) {
        var jhr = $.ajax({
          url: url,
          type: 'POST',
          dataType: "script",
          data: { ids: ids }
        });

        jhr.success(function () {
          $('#flash-messages').html('<div class="alert alert-success fade in"><i class="fa-fw fa fa-check"></i>Registros ativados com sucesso!!</div>');
        });

        jhr.error(function (jqXHR, textStatus, errorThrown) {
          $('#flash-messages').html('<div class="alert alert-danger fade in"><i class="fa-fw fa fa-times"></i>Os registros não foram ativados.</div>');
        });
      }
    }
  });
});
