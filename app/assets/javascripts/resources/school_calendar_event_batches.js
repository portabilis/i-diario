$(function () {
  'use strict';

  var $legendContainer = $('[data-event-batch-legend-container]'),
      $checkboxContainer = $('[data-event-batch-checkbox-container]'),
      $eventType = $('#school_calendar_event_batch_event_type');

  var isEventTypeEqualTo = function(type) {
    return $eventType.val() === type;
  }

  var eventTypeIsBlank = function() {
    return isEventTypeEqualTo('');
  }

  var eventTypeIsExtraSchool = function() {
    return isEventTypeEqualTo('extra_school');
  }

  var eventTypeIsExtraSchool = function() {
    return isEventTypeEqualTo('extra_school');
  }

  var eventTypeIsNoSchoolWithFrequency = function() {
    return isEventTypeEqualTo('no_school_with_frequency');
  }

  var shouldHideLegend = function() {
    return eventTypeIsBlank() || eventTypeIsExtraSchool() || eventTypeIsNoSchoolWithFrequency();
  }

  var shouldShowCheckbox = function() {
    return eventTypeIsExtraSchool();
  }

   var togleLegendContainerVisibility = function() {
    if (shouldHideLegend()) {
      $legendContainer.addClass('hidden');
    } else {
      $legendContainer.removeClass('hidden');
    }
  }

  var togleCheckboxContainerVisibility = function() {
    if (shouldShowCheckbox()) {
      $checkboxContainer.removeClass('hidden');
    } else {
      $checkboxContainer.addClass('hidden');
    }
  }

  $eventType.on('change', togleLegendContainerVisibility);
  togleLegendContainerVisibility();

  $eventType.on('change', togleCheckboxContainerVisibility);
  togleCheckboxContainerVisibility();
});
