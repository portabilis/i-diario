$(document).ready( function() {
  let beta_title = 'Este recurso ainda está em processo de desenvolvimento e pode apresentar problemas'
  let img_src = $('#image-beta').attr('src');
  $('.fa-check-square-o').closest('h2').after(`<img src="${img_src}" class="beta-badge" style="margin-bottom: 9px; margin-left: 5px" title="${beta_title}">`);

  window.disciplines = [];

  var flashMessages = new FlashMessages(),
      $classroom = $("#frequency_in_batch_form_classroom_id"),
      $discipline = $("#frequency_in_batch_form_discipline_id");

  var fetchDisciplines = function (params, callback) {
    if (_.isEmpty(window.disciplines)) {
      $.getJSON('/disciplinas?' + $.param(params)).always(function (data) {
        window.disciplines = data;
        callback(window.disciplines);
      });
    } else {
      callback(window.disciplines);
    }
  };

  $classroom.on('change', async function (e) {
    await getFrequencyType();

    var params = {
      classroom_id: e.val
    };

    window.disciplines = [];
    $discipline.val('').select2({ data: [] });

    if (!_.isEmpty(e.val)) {
      fetchDisciplines(params, function (disciplines) {
        var selectedDisciplines = _.map(disciplines, function (discipline) {
          return { id:discipline['id'], text: discipline['description'] };
        });

        $discipline.select2({
          data: selectedDisciplines
        });
      });
    }
  });

  async function getFrequencyType() {
    let classroom_id = $classroom.select2('val');

    if (!_.isEmpty(classroom_id)) {
      return $.ajax({
        url: Routes.fetch_frequency_type_daily_frequencies_in_batchs_pt_br_path({
          classroom_id: classroom_id,
          format: 'json'
        }),
        success: handleFetchFrequencyTypeSuccess,
        error: handleFetchFrequencyTypeError
      });
    }
  }

  function handleFetchFrequencyTypeSuccess(data) {
    let FREQUENCY_BY_DISCIPLINE = '2'

    if (data == FREQUENCY_BY_DISCIPLINE) {
      $('.frequency_in_batch_form_discipline_id').show();
    } else {
      $('.frequency_in_batch_form_discipline_id').hide()
    }
  };

  function handleFetchFrequencyTypeError() {
    flashMessages.error('Ocorreu um erro ao buscar o o tipo da frequencia.');
  };

})
