$(function() {
  function addInfoMessage() {
    var infoTitle = '';
    var infoDescription = '';
    var kind = String($('#maintenance_adjustment_kind').val());

    switch(kind) {
      case 'absence_adjustments':
        infoTitle = 'Ajuste de faltas:';
        infoDescription = 'Ajusta as faltas que foram lançadas com regra de avaliação incorreta.';
        break;
    }

    $('#info_title').text(infoTitle);
    $('#info_description').text(infoDescription);

    if(kind) {
      $('#maintenance_adjustment_info').removeClass('hidden');
    } else {
      $('#maintenance_adjustment_info').addClass('hidden');
    }
  }

  $('#maintenance_adjustment_kind').change(function() {
    addInfoMessage();
  });

  addInfoMessage();
});
