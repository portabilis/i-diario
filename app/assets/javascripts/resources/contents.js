$(function () {
  window.classrooms = [];
  window.disciplines = [];

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

  function hiddenField(){
    if($('#content_classroom_id').val()){
      $.getJSON('/classrooms/' + $('#content_classroom_id').val()).always(function (data) {
        if(data.score_type == '2'){
          $('.content_knowledge_area').show();
          $('.content_discipline').hide();
          $('#content_discipline_id').val('');
        }else if(data.score_type == '1'){
          $('.content_knowledge_area').hide();
          $('.content_discipline').show();
          $('#content_knowledge_area_id').val('');
        }
      });
    }
    if($('#content_unity_id').val() == ''){
      $('.content_knowledge_area').hide();
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
        $knowledge_area =  $('#content_knowledge_area_id'),
        params = {
          classroom_id: e.val
        };
    window.disciplines = [];
    window.knowledge_areas = [];

    if (_.isEmpty(e.val)) {
      $discipline.val('');
      $discipline.select2({
        data: []
      });

      $knowledge_area.val('');
      $knowledge_area.select2({
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
      fetchKnowledgeAreas(params, function (knowledge_areas) {
        var selectedKnowledgeAreas = _.map(knowledge_areas, function (knowledge_area) {
          return { id:knowledge_area['id'], text: knowledge_area['description'] };
        });

        $knowledge_area.select2({
          data: selectedKnowledgeAreas
        });
      });

      hiddenField();
    }
  });
});
