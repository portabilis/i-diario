$(function() {
  'use strict';

  $('#general_configuration_max_descriptive_exam_character_count').regexMask(/^\d+$/);

  var notify_absences = $('#general_configuration_notify_consecutive_or_alternate_absences');

  notify_absences.change(function() {
    if ($(this).prop('checked')) {
      $('#notify_consecutive_or_alternate_absences_fields').show();
    } else {
      $('#notify_consecutive_or_alternate_absences_fields').hide();
    }
  });

  notify_absences.trigger('change');
});
