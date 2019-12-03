$(function() {
  function profileChanged(){
    var $daily_note_classroom_id = $('#daily_note_classroom_id').val();
    var $daily_note_discipline_id = $('#daily_note_discipline_id').val();

    var filter = {
      current_classroom_id: $daily_note_classroom_id,
      current_discipline_id: $daily_note_discipline_id
    }

    $.ajax({
      url: Routes.profile_changed_daily_notes_pt_br_path({ filter: filter, format: 'json' }),
      success: handleRequestSuccess,
      error: handleRequestError
    });
  }

  function handleRequestSuccess(changed) {
    if (changed){
      location.reload();
    }
  };

  function handleRequestError() {
    flashMessages.error('Ocorreu um erro desconhecido');
  };

  function handleVisibilityChange() {
    if (document.visibilityState == "visible") {
      profileChanged()
    }
  }

  document.addEventListener('visibilitychange', handleVisibilityChange, false);
});
