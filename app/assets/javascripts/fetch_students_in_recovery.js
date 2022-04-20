let dateRegex = '^(?:(?:31(\\/)(?:0?[13578]|1[02]))\\1|(?:(?:29|30)(\\/)(?:0?[1,3-9]|1[0-2])\\2))(?:(?:1[6-9]|[2-9]\\d)?\\d{2})$|^(?:29(\\/)0?2\\3(?:(?:(?:1[6-9]|[2-9]\\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00))))$|^(?:0?[1-9]|1\\d|2[0-8])(\\/)(?:(?:0?[1-9])|(?:1[0-2]))\\4(?:(?:1[6-9]|[2-9]\\d)?\\d{2})$';
let $recorded_at = null;

function fetchStudentsInRecovery(classroom, discipline, exam_rule, step_id, recorded_at, success_callback) {
  $recorded_at = recorded_at
  if (!_.isEmpty(step_id) && !_.isEmpty(recorded_at.match(dateRegex)) && exam_rule.recovery_type !== 0) {
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
