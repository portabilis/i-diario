$(function () {
  window.classrooms = [];
  window.disciplines = [];
  var $classroom = $('#content_classroom_id'),
      $content_classes = $(".content_classes");

  hiddenField();

  var fetchClassrooms = function (params, callback) {
    if (_.isEmpty(window.classrooms)) {
      $.getJSON('/classrooms?' + $.param(params)).always(function (data) {
        window.classrooms = data;
        callback(window.classrooms);
      });
    } else {
      callback(window.classrooms);
    }
  };

  var fetchDisciplines = function (params, callback) {
    if (_.isEmpty(window.disciplines)) {
      $.getJSON('/disciplines?' + $.param(params)).always(function (data) {
        window.disciplines = data;
        callback(window.disciplines);
      });
    } else {
      callback(window.disciplines);
    }
  };

  var fetchKnowledgeAreas = function (params, callback) {
    if (_.isEmpty(window.knowledge_areas)) {
      $.getJSON('/knowledge_areas?' + $.param(params)).always(function (data) {
        window.knowledge_areas = data;
        callback(window.knowledge_areas);
      });
    } else {
      callback(window.knowledge_areas);
    }
  };

  var fetchExamRule = function (params, callback) {
    $.getJSON('/exam_rules?' + $.param(params)).always(function (data) {
      callback(data);
    });
  };

  $('#content_unity_id').on('change', function (e) {
    var params = {
      unity_id: e.val
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

  var checkExamRule = function(params){
    fetchExamRule(params, function(exam_rule){
      $('form input[type=submit]').removeClass('disabled');
      if(!$.isEmptyObject(exam_rule)){

        if(exam_rule.frequency_type == 1){
          $('#content_classes').select2('val', '');
          $content_classes.hide();
        }else{
          $content_classes.show();
        }
      }else{
        $('#content_classes').select2('val', '');
        $content_classes.hide();
      }
    });
  }

  if ($('#content_classroom_id').select2('val')) {
    var params = {
      classroom_id: $('#content_classroom_id').select2('val')
    };

    checkExamRule(params);
  }

  $classroom.on('change', function (e) {
    var params = {
      classroom_id: e.val
    };
    if (!_.isEmpty(e.val) && e.val != 'empty') {
      checkExamRule(params);
    }
  });

  function hiddenField(){
    if($('#content_classroom_id').val()){
      $.getJSON('/classrooms/' + $('#content_classroom_id').val()).always(function (data) {
        if(data.score_type == '2'){
          $('#content_discipline_id').select2('val', '');
          $('.content_discipline').hide();
        }else if(data.score_type == '1'){
          $('.content_discipline').show();
        }
      });
    }
    if($('#content_classroom_id').val() == ''){
      $('#content_discipline_id').select2('val', '');
      $('.content_discipline').hide();
    }
  }


  $('#content_unity_id').on('change', function (e) {
    var $classroom = $('#content_classroom_id'),
        params = {
          unity_id: e.val
        };

    window.classrooms = [];

    if (_.isEmpty(e.val)) {
      $classroom.val('');
      $classroom.select2({
        data: []
      });

    } else {
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

  $('#content_classroom_id').on('change', function (e) {
    var $discipline = $('#content_discipline_id'),
        params = {
          classroom_id: e.val
        };
    window.disciplines = [];

    if (_.isEmpty(e.val)) {
      $discipline.select2('val', '');
      $discipline.select2({
        data: []
      });


    } else {
      fetchDisciplines(params, function (disciplines) {
        var selectedDisciplines = _.map(disciplines, function (discipline) {
          return { id:discipline['id'], text: discipline['description'] };
        });

        $discipline.select2({
          data: selectedDisciplines
        });
      });

      hiddenField();
    }
  });
});
