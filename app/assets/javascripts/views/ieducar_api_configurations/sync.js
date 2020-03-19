$(function () {
  'use strict';

  var $time_running = $('#time_running');
  var $done_percentage = $('#done_percentage');

  function refreshDonePercentage() {
    if($done_percentage.text() == '') {
      return
    }

    $.ajax({
      beforeSend: function () {},
      complete: function () {},
      url: Routes.current_syncronization_data_ieducar_api_configurations_synchronizations_pt_br_path({
        format: 'json'
      }),
      async: false,
      success: handleFetchCurrentSyncronizationDataSuccess,
      error: handleFetchCurrentSyncronizationDataError
    });
  }

  function handleFetchCurrentSyncronizationDataSuccess(data) {
    if(data.done_percentage == null) {
      location.reload();
    } else {
      $time_running.text(data.time_running);
      $done_percentage.text(data.done_percentage);
    }
  }

  function handleFetchCurrentSyncronizationDataError() {
    flashMessages.error('Ocorreu um erro ao buscar os dados da sincronização atual.');
  }

  setInterval(function() {
    refreshDonePercentage();
  }, 5000);
});
