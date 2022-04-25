function fetchStudentsInRecovery(classroom, discipline, exam_rule, step_id, recorded_at, success_callback) {
  if (_.isEmpty(step_id) || _.isEmpty(moment(recorded_at, 'MM-DD-YYYY')._i) || exam_rule.recovery_type === 0) {
    return;
  }

  $.ajax({
    url: Routes.in_recovery_students_pt_br_path({
      classroom_id: classroom,
      discipline_id: discipline,
      step_id: step_id,
      date: recorded_at,
      format: 'json'
    }),
    success: success_callback,
    error: handleFetchStudentsInRecoveryError
  });
}

function hideNoItemMessage() {
  $('.no_item_found').hide();
}

function loadDecimalMasks() {
  let numberOfDecimalPlaces = $('#recovery-diary-record-students').data('scale');
  $('.nested-fields input.decimal').inputmask('customDecimal', { digits: numberOfDecimalPlaces });
}

function handleFetchStudentsInRecoveryError() {
  flashMessages.error('Ocorreu um erro ao buscar os alunos.');
}
