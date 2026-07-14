$(function() {
  'use strict';

  var $wizard = $('#pei-wizard');
  if ($wizard.length === 0) { return; }

  var $tabs = $wizard.find('.nav-tabs li');
  var $tabLinks = $wizard.find('.nav-tabs li a');
  var $studentSelect = $('.iep-student-select');
  var $classroomSelect = $('.iep-classroom-select');

  // ---- Navegação em passos (abas Bootstrap + Próxima/Anterior) ----
  function currentIndex() {
    return $tabs.index($wizard.find('.nav-tabs li.active'));
  }

  function showStep(index) {
    if (index < 0 || index >= $tabLinks.length) { return; }
    $tabLinks.eq(index).tab('show');
  }

  function refreshButtons() {
    var index = currentIndex();
    var last = $tabs.length - 1;

    $('.pei-wizard-prev').toggle(index > 0);
    $('.pei-wizard-next').toggle(index < last);
    $('.pei-wizard-finish').toggle(index === last);
  }

  $('.pei-wizard-next').on('click', function() { showStep(currentIndex() + 1); });
  $('.pei-wizard-prev').on('click', function() { showStep(currentIndex() - 1); });
  $tabLinks.on('shown.bs.tab', refreshButtons);
  refreshButtons();

  // ---- Prefill dos dados do aluno (seção 1) ----
  $studentSelect.on('change', function() {
    var studentId = $(this).val();
    if (!studentId || studentId === 'empty') { return; }

    $.getJSON(
      Routes.student_data_individualized_educational_plans_pt_br_path({ student_id: studentId, format: 'json' }),
      function(data) {
        $('.iep-birth-date').val(data.birth_date || '');
        $('.iep-guardians').val(data.guardians || '');
        $('.iep-diagnosis').val(data.diagnosis || '');
        loadClassrooms(data.classrooms || []);
      }
    );
  });

  function loadClassrooms(classrooms) {
    var options = classrooms.map(function(classroom) {
      return { id: classroom.id, text: classroom.name, shift: classroom.shift };
    });
    options.unshift({ id: 'empty', text: '' });

    $classroomSelect.select2('destroy');
    $classroomSelect.empty().val(null);
    $classroomSelect.select2({ data: options, allowClear: true, theme: 'classic' });

    if (classrooms.length === 1) {
      $classroomSelect.select2('val', classrooms[0].id);
      $('.iep-shift').val(classrooms[0].shift || '');
    } else {
      $('.iep-shift').val('');
    }
  }

  $classroomSelect.on('change', function() {
    var selected = $(this).select2('data');
    $('.iep-shift').val(selected && selected.shift ? selected.shift : '');
  });
});
