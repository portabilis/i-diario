$(function () {
  window.classrooms = [];
  window.disciplines = [];
  window.avaliations = [];

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
      $.getJSON('/disciplinas?' + $.param(params)).always(function (data) {
        window.disciplines = data;
        callback(window.disciplines);
      });
    } else {
      callback(window.disciplines);
    }
  };

  var fetchAvaliations = function (params, callback) {
    if (_.isEmpty(window.avaliations)) {
      $.getJSON('/teacher_avaliations?' + $.param(params)).always(function (data) {
        window.avaliations = data;
        callback(window.avaliations);
      });
    } else {
      callback(window.avaliations);
    }
  };

  var $classroom = $('#daily_note_classroom_id');
  var $discipline = $('#daily_note_discipline_id');
  var $avaliation = $('#daily_note_avaliation_id');


  $('#daily_note_unity_id').on('change', function (e) {
    var params = {
      filter:{
        by_unity: e.val,
      },
      find_by_current_teacher: true
    };

    window.classrooms = [];
    window.disciplines = [];
    window.avaliations = [];
    $classroom.val('').select2({ data: [] });
    $discipline.val('').select2({ data: [] });
    $avaliation.val('').select2({ data: [] });

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

  $('#daily_note_classroom_id').on('change', function (e) {
    var params = {
      classroom_id: e.val
    };

    window.disciplines = [];
    window.avaliations = [];
    $discipline.val('').select2({ data: [] });
    $avaliation.val('').select2({ data: [] });

    if (!_.isEmpty(e.val)) {
      fetchDisciplines(params, function (disciplines) {
        var selectedDisciplines = _.map(disciplines, function (discipline) {
          return { id:discipline['id'], text: discipline['description'] };
        });

        $discipline.select2({
          data: selectedDisciplines
        });
      });
    }
  });

  $('#daily_note_discipline_id').on('change', function (e) {
    var daily_note_discipline_select = this;

    fetchAvaliationsRequest(daily_note_discipline_select);
  });

  function fetchAvaliationsRequest(daily_note_discipline_select) {
    var params = {
      discipline_id: $(daily_note_discipline_select).val(),
      classroom_id: $('#daily_note_classroom_id').val()
    };

    window.avaliations = [];
    $avaliation.val('').select2({ data: [] });

    if (!_.isEmpty($(daily_note_discipline_select).val())) {
      fetchAvaliations(params, function (avaliations) {
        var selectedAvaliations = _.map(avaliations, function (avaliation) {
          return { id: avaliation['id'], text: avaliation['description'] };
        });

        $avaliation.select2({
          data: selectedAvaliations
        });
      });
    }
  }

  fetchAvaliationsRequest($('#daily_note_discipline_id'));

  $('input.string[id^=daily_note_students_attributes][id*=_note]').bind("keypress", function(e) {
    if (e.keyCode == 13) {
      e.preventDefault();
      var inps = $('input.string[id^=daily_note_students_attributes][id*=_note]');
      for (var x = 0; x < inps.length; x++) {
        if (inps[x] == this) {
          while (inps[x + 1] && (inps[x]).name == (inps[x + 1]).name) {
            x++;
          }
          if ((x + 1) < inps.length) $(inps[x + 1]).focus();
        }
      }
    }
  });

  var checkBoxes = $('.exempt_student_check'),
      exemptButton = $('#exempt_students_button'),
      studentsIds = $('#exemption_students_ids');

  $(document).on('click', 'a.open-exemption-modal', function(){
    var title = 'Tem certeza que deseja dispensar este aluno?'

    if($(this).attr('id') == 'exempt_students_button'){
      title = 'Tem certeza que deseja dispensar os alunos selecionados?';
    } else {
      studentsIds.val($(this).data('student-id'));
    }

    $('.modal-title').text(title);
    $('#exemption-modal').modal('show');
  });

  $('#exemption-modal').on('hidden.bs.modal', function () {
    studentsIds.val('');
  });

  $('#exemption-modal').on('show.bs.modal', function () {
    $('#reason').val('');
    $('#exemption-modal button:submit').attr('disabled', true);
  });

  $('#reason').keyup(function(){
    if($(this).val().trim().length !=0) {
      $('#exemption-modal button:submit').attr('disabled', false);
    } else {
      $('#exemption-modal button:submit').attr('disabled',true);
    }
  });

  function updateStudentIds(checked, value) {
    var studentsIdsCurrentValue = studentsIds.val();

    if(checked) {
      if (studentsIdsCurrentValue){
        studentsIds.val(studentsIdsCurrentValue + ',' + value);
      } else{
        studentsIds.val(value);
      }
    } else {
      var newList = removeStudentId(studentsIdsCurrentValue, value);
      studentsIds.val(newList);
    }
  }

  function removeStudentId(list, id) {
    separator = ",";
    var values = list.split(separator);
    for(var i = 0 ; i < values.length ; i++) {
      if(values[i] == id) {
        values.splice(i, 1);
        return values.join(separator);
      }
    }
    return list;
  }

  function toggleExemptionButtonState(enabled){
    exemptButton.attr('disabled', !enabled);

    if (enabled) {
      exemptButton.removeClass('btn-exempt-students-disabled');
      exemptButton.addClass('btn-exempt-students-enabled');
    } else {
      exemptButton.addClass('btn-exempt-students-disabled');
      exemptButton.removeClass('btn-exempt-students-enabled');
    }
  }

  function updateBackgound(checked, student_id) {
    if (checked) {
      $('#tr_student_'+ student_id).addClass('selected-student-tr');
    } else {
      $('#tr_student_'+ student_id).removeClass('selected-student-tr');
    }
  }

  checkBoxes.click(function() {
    var checked = checkBoxes.is(":checked");

    updateBackgound($(this).is(":checked"), this.value);
    toggleExemptionButtonState(checked);
    updateStudentIds($(this).is(":checked"), this.value)
  });

  $('.exempt_student_check_all:input').change(function() {
    var enabledCheckoxes = $('.exempt_student_check');

    if (enabledCheckoxes.length > 0) {
      var check_all = this.checked;
      studentsIds.val('');
      enabledCheckoxes.prop('checked', check_all);
      $.each(enabledCheckoxes, function(i, element){
        updateBackgound(check_all, element.value);
        updateStudentIds(check_all, element.value);
      });
      toggleExemptionButtonState(check_all);
    }
  });
});
