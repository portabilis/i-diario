$(function () {
  'use strict';

  var flashMessages = new FlashMessages();
  var $classroom = $('#partial_score_record_report_form_classroom_id');
  var $unity = $('#partial_score_record_report_form_unity_id');
  var $student = $('#partial_score_record_report_form_student_id');
  var $classroomStepContainer = $('[classroom-step-container]');
  var $schoolStepContainer = $('[school-step-container]');
  var $school_calendar_classroom_step = $('#partial_score_record_report_form_school_calendar_classroom_step_id');
  var $school_calendar_step = $('#partial_score_record_report_form_school_calendar_step_id');
  var $current_school_calendar_year = $('#partial_score_record_report_form_school_calendar_year');

  function fetchStudents() {
    var classroom_id = $classroom.select2('val');

    $student.select2('val', '');
    $student.select2({ data: [] });

    if (!_.isEmpty(classroom_id)) {

      $.ajax({
        url: Routes.students_by_daily_note_pt_br_path({
          classroom_id: classroom_id,
          score_type: 'numeric',
          format: 'json'
        }),
        success: fetchStudentsSuccess,
        error: fetchStudentsError
      });
    }
  };

  $classroom.on('change', function () {
    fetchStudents();
    fetchSchoolSteps();
    fetchClassroomSteps();
  });

  function fetchStudentsSuccess(data) {
    var students = _.map(data.partial_score_record_report, function(student) {
      return { id: student.id, text: student.name };
    });

    $student.select2({ data: students });
  };

  function fetchStudentsError() {
    flashMessages.error('Ocorreu um erro ao buscar os alunos!')
  };

  function toggleStepField() {
    if (!_.isEmpty($classroom.select2('val'))) {
      fetchSchoolSteps();
      fetchClassroomSteps();
    }
  }

  // on load
  toggleStepField();

  function fetchSchoolSteps() {
    var unity_id = $unity.select2('val');
    $school_calendar_step.select2('val', '');
    $school_calendar_step.select2({ data: [] });

    if (!_.isEmpty(unity_id)) {
      var filter = {
        by_unity: unity_id,
        by_year: $current_school_calendar_year.val()
      };
      $.ajax({
        url: Routes.school_calendar_steps_pt_br_path({
          filter: filter,
          format: 'json'
        }),
        success: fetchSchoolStepsSuccess,
        error: fetchSchoolStepsError
      });
    }
  };

  function fetchSchoolStepsSuccess(data) {
    var school_steps = _.map(data.school_calendar_steps, function (school_calendar_step) {
      return { id: school_calendar_step.id, text: school_calendar_step.school_term };
    });

    $school_calendar_step.select2({ data: school_steps});
  };

  function fetchSchoolStepsError() {
    flashMessages.error('Ocorreu um erro ao buscar as etapas!')
  };

  function fetchClassroomSteps() {
    var classroom_id = $classroom.select2('val');

    $school_calendar_classroom_step.select2('val', '');
    $school_calendar_classroom_step.select2({ data: [] });

    if (!_.isEmpty(classroom_id)) {
      var filter = {
        by_classroom: classroom_id
      };
      $.ajax({
        url: Routes.school_calendar_classroom_steps_pt_br_path({
          filter: filter,
          format: 'json'
        }),
        success: fetchClassroomsStepsSuccess,
        error: fetchClassroomsStepsError
      });
    }
  };

  function fetchClassroomsStepsSuccess(data) {
    var classroom_steps = _.map(data.school_calendar_classroom_steps, function (school_calendar_classroom_step) {
      return { id: school_calendar_classroom_step.id, text: school_calendar_classroom_step.school_term };
    });

    if (!_.isEmpty(classroom_steps)) {
      $schoolStepContainer.addClass("hidden");
      $classroomStepContainer.removeClass("hidden");
    }else {
      $schoolStepContainer.removeClass("hidden");
      $classroomStepContainer.addClass("hidden");
    }

    $school_calendar_classroom_step.select2({ data: classroom_steps});
  };

  function fetchClassroomsStepsError() {
    flashMessages.error('Ocorreu um erro ao buscar as etapas!')
  };
});
