let $loadingClone = $('#page-loading').clone(true).appendTo('body');

function fetchStudentsInRecovery(classroom, discipline, exam_rule, step_id, recorded_at, success_callback) {
  let date = moment(recorded_at, 'DD/MM/YYYY', true);
  if (_.isEmpty(step_id) || _.isEmpty(date._i) || !date.isValid() || exam_rule.recovery_type === 0) {
    return;
  }

  $loadingClone.removeClass('hidden');

  success_callback = (function() {
    let cached_function = success_callback;
    return function() {
      cached_function.apply(this, arguments);
      $loadingClone.addClass('hidden');
    };
  })();

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
  $loadingClone.addClass('hidden');
  flashMessages.error('Ocorreu um erro ao buscar os alunos.');
}
