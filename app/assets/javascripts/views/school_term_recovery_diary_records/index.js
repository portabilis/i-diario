$(function() {
  'use strict';

  var $classroomFilter = $('#filter_by_classroom_id');
  var $stepFilter = $('#filter_by_step_id');

  if ($classroomFilter.length === 0 || $stepFilter.length === 0) {
    return;
  }

  function isEmptyValue(value) {
    return !value || value === 'empty' || value === '';
  }

  function updateStepsFilter(classroomId) {
    var params = {};

    if (!isEmptyValue(classroomId)) {
      params.classroom_id = classroomId;
    }

    $.getJSON('/school_term_recovery_diary_records/fetch_steps_for_filter', params, function(data) {
      $stepFilter.select2('destroy');
      $stepFilter.data('elements', data);

      $stepFilter.select2({
        formatResult: function(el) {
          if (el.children) {
            return "<div class='select2-result-label'><strong>" + (el.text || el.name) + "</strong></div>";
          }
          return "<div class='select2-user-result'>" + (el.name || el.text) + "</div>";
        },
        formatSelection: function(el) {
          return "<div class='select2-user-result'>" + (el.text || el.name) + "</div>";
        },
        data: data,
        allowClear: true,
        theme: 'classic'
      });
    });
  }

  // Limpa o step antes do form ser serializado pelo index.js global
  $classroomFilter.on('select2-selecting select2-clearing', function() {
    $stepFilter.val('');
  });

  $classroomFilter.on('change', function(e) {
    updateStepsFilter(isEmptyValue(e.val) ? '' : e.val);
  });

  // Atualiza etapas agrupadas se nenhuma turma estiver selecionada
  if (isEmptyValue($classroomFilter.val())) {
    updateStepsFilter('');
  }
});
