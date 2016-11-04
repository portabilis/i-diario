$(function () {
  'use strict';
  window.grades = [];
  window.classrooms = [];
  window.disciplines = [];

  var $legendContainer = $('[data-event-legend-container]'),
      $eventType = $('#school_calendar_event_event_type'),
      $unity = $('#school_calendar_event_unity_id'),
      $course = $('#school_calendar_event_course_id'),
      $grade = $('#school_calendar_event_grade_id'),
      $classroom = $('#school_calendar_event_classroom_id'),
      $discipline = $('#school_calendar_event_discipline_id');

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

  var fetchDisciplines = function (params, callback) {
    if (_.isEmpty(window.disciplines)) {
      $.getJSON(Routes.search_disciplines_pt_br_path(params)).always(function (data) {
        window.disciplines = data.disciplines;
        callback(window.disciplines);
      });
    } else {
      callback(window.disciplines);
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
    window.disciplines = [];

    $grade.val('').select2({ data: [] });
    $classroom.val('').select2({ data: [] });
    $discipline.val('').select2({ data: [] });

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
        by_unity: $unity.val(),
        by_year: $("#year").val()
      }
    };

    window.classrooms = [];
    window.disciplines = [];

    $classroom.val('').select2({ data: [] });
    $discipline.val('').select2({ data: [] });

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

  $classroom.on('change', function (e) {
    var params = {
      filter: {
        by_classroom: e.val,
        by_unity_id: $unity.val()
      }
    };

    window.disciplines = [];

    $discipline.val('').select2({ data: [] });

    if (!_.isEmpty(e.val)) {
      fetchDisciplines(params, function (disciplines) {
        var selectedDisciplines = _.map(disciplines, function (discipline) {
          return { id:discipline['id'], text: discipline['description'] };
        });
        selectedDisciplines.unshift({ id: '', name: '<option>Todas</option>', text: 'Todas' });

        $discipline.select2({
          data: selectedDisciplines
        });
        $discipline.val($discipline.find('option:first-child').val()).trigger('change');
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
