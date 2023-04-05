$(function () {
  window.classrooms = [];
  window.disciplines = [];
  const PERIOD_FULL = 4;

  var $hideWhenGlobalAbsence = $(".hide-when-global-absence"),
      $globalAbsence = $("#attendance_record_report_form_global_absence"),
      $examRuleNotFoundAlert = $('#exam-rule-not-found-alert'),
      $selectAllClasses = $('#select-all-classes'),
      $deselectAllClasses = $('#deselect-all-classes');

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

  var fetchExamRule = function (params, callback) {
    $.getJSON('/exam_rules?' + $.param(params)).always(function (data) {
      callback(data);
    });
  };

  var $classroom = $('#attendance_record_report_form_classroom_id');
  var $discipline = $('#attendance_record_report_form_discipline_id');
  var $class_numbers = $('#attendance_record_report_form_class_numbers');

  var checkExamRule = function(params){
    fetchExamRule(params, function(data){
      var examRule = data.exam_rule;
      $('form input[type=submit]').removeClass('disabled');
      if(!$.isEmptyObject(examRule)){
        $examRuleNotFoundAlert.addClass('hidden');
        if(examRule.frequency_type == 2 || examRule.allow_frequency_by_discipline){
          $globalAbsence.val(0);
          $hideWhenGlobalAbsence.show();
        }else{
          $globalAbsence.val(1);
          $hideWhenGlobalAbsence.hide();
        }

      }else{
        $globalAbsence.val(0);
        $hideWhenGlobalAbsence.hide();

        // Display alert
        $examRuleNotFoundAlert.removeClass('hidden');

        // Disable form submit
        $('form input[type=submit]').addClass('disabled');
      }
    });
  }

  $classroom.on('change', function (e) {
    var params = {
      classroom_id: e.val
    };

    window.disciplines = [];
    $discipline.val('').select2({ data: [] });
    $('#attendance_record_report_form_class_numbers').select2("val", "")


    if (!_.isEmpty(e.val)) {
      checkExamRule(params);

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

  $discipline.on('change', async function () {
    $('#attendance_record_report_form_period').select2('val', '');
    await getPeriod();
  });

  async function getPeriod() {
    let classroom_id = $('#attendance_record_report_form_classroom_id').select2('val');
    let discipline_id  = $('#attendance_record_report_form_discipline_id').select2('val');

    if (!_.isEmpty(classroom_id)) {
      return $.ajax({
        url: Routes.period_attendance_record_report_pt_br_path({
          classroom_id: classroom_id,
          discipline_id: discipline_id,
          format: 'json'
        }),
        success: handleFetchPeriodByClassroomSuccess,
        error: handleFetchPeriodByClassroomError
      });
    }
  }

  function handleFetchPeriodByClassroomSuccess(data) {
    $('#attendance_record_report_form_classroom_id').val(data);
    let period = $('#attendance_record_report_form_period');

    if (data != PERIOD_FULL) {
      getNumberOfClasses();
      period.val(data).trigger("change")
      period.attr('readonly', true)
    } else {
      console.log('false', data)
      period.attr('readonly', false)
    }
  };

  function handleFetchPeriodByClassroomError() {
    flashMessages.error('Ocorreu um erro ao buscar o período da turma.');
  };

  function getNumberOfClasses() {
    let classroom_id = $('#attendance_record_report_form_classroom_id').select2('val');

    $.ajax({
      url: Routes.number_of_classes_attendance_record_report_pt_br_path({
        classroom_id: classroom_id,
        format: 'json'
      }),
      success: handleFetchNumberOfClassesByClassroomSuccess,
      error: handleFetchNumberOfClassesByClassroomError
    });
  }

  function handleFetchNumberOfClassesByClassroomSuccess(data) {
    var elements = []
    var class_numbers = $class_numbers

    for (let i = 1; i <= data; i++){
      elements.push({id: i, name: i, text: i})
    }
    // var first_class_number = elements[0]

    class_numbers.select2('data', elements);
  }

  function handleFetchNumberOfClassesByClassroomError() {
    flashMessages.error('Ocorreu um erro ao buscar os numeros de aula da turma.');
  }
    
  $selectAllClasses.on('click', function(){
    var allElements = $.parseJSON($("#attendance_record_report_form_class_numbers").attr('data-elements'));
    var joinedElements = "";

    $.each(allElements, function(index, element){
      joinedElements = joinedElements + element.name + ",";
    });

    $class_numbers.val(joinedElements);
    $class_numbers.trigger("change");

    $selectAllClasses.hide();
    $deselectAllClasses.show();
  });

  $deselectAllClasses.on('click', function(){

    $class_numbers.val("");
    $class_numbers.trigger("change");

    $selectAllClasses.show();
    $deselectAllClasses.hide();
  });

  $hideWhenGlobalAbsence.hide();

  if ($classroom.length && $classroom.val().length){
    checkExamRule({classroom_id: $classroom.val()});
  }
});
