$(function () {
  'use strict';
  window.grades = [];
  window.classrooms = [];

  var $legendContainer = $('[data-event-legend-container]'),
      $eventType = $('#school_calendar_event_event_type'),
      $unity = $('#school_calendar_event_unity_id'),
      $course = $('#school_calendar_event_course_id'),
      $grade = $('#school_calendar_event_grade_id'),
      $classroom = $('#school_calendar_event_classroom_id');

  var fetchGrades = function (params, callback) {
    if (_.isEmpty(window.grades)) {
      $.getJSON(Routes.grades_pt_br_path(params)).always(function (data) {
        window.grades = data;
        callback(window.grades);
      });
    } else {
      callback(window.grades);
    }
  };

  var fetchClassrooms = function (params, callback) {
    if (_.isEmpty(window.classrooms)) {
      $.getJSON(Routes.classrooms_pt_br_path(params)).always(function (data) {
        window.classrooms = data;
        callback(window.classrooms);
      });
    } else {
      callback(window.classrooms);
    }
  };

  $course.on('change', function (e) {
    var params = {
      filter: {
        by_course: e.val,
        by_unity: $unity.val()
      }
    };

    window.grades = [];
    window.classrooms = [];

    $grade.val('').select2({ data: [] });
    $classroom.val('').select2({ data: [] });

    if (!_.isEmpty(e.val)) {
      fetchGrades(params, function (grades) {
        var selectedGrades = _.map(grades, function (grade) {
          return { id:grade['id'], text: grade['description'] };
        });

        $grade.select2({
          data: selectedGrades
        });
      });
    }
  });

  $grade.on('change', function (e) {
    var params = {
      filter: {
        by_grade: e.val,
        by_unity: $unity.val()
      }
    };

    window.classrooms = [];

    $classroom.val('').select2({ data: [] });

    if (!_.isEmpty(e.val)) {
      fetchClassrooms(params, function (classrooms) {
        var selectedClassrooms = _.map(classrooms, function (classroom) {
          return { id:classroom['id'], text: classroom['description'] };
        });

        $classroom.select2({
          data: selectedClassrooms
        });
      });
    }
  });

  var togleLegendContainerVisibility = function(){
    if($eventType.val() != "extra_school" && $eventType.val() != ""){
      $legendContainer.removeClass("hidden");
    }else{
      $legendContainer.addClass("hidden");
    }
  }

  $eventType.on('change', togleLegendContainerVisibility);
  togleLegendContainerVisibility();
});
