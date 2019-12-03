$(function() {
  function profileChanged(){
    var $exam_record_report_form_classroom_id = $('#exam_record_report_form_classroom_id').val();
    var $exam_record_report_form_discipline_id = $('#exam_record_report_form_discipline_id').val();

    var filter = {
      current_classroom_id: $exam_record_report_form_classroom_id,
      current_discipline_id: $exam_record_report_form_discipline_id
    }

    $.ajax({
      url: Routes.reports_exam_record_profile_changed_pt_br_path({ filter: filter, format: 'json' }),
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
