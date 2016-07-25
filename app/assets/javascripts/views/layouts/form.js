 $(function(){

  var role_unity_id = null;
  var flashMessages = new FlashMessages();
  $("form#user-role").on("ajax:success", function(event, data, status, xhr){
    $("form#user-role").clear_form_fields();
    $("form#user-role").clear_form_errors();
    location.reload();
    }).on("ajax:error", function(event, data, status, xhr){
      $("form#user-role").render_form_errors('user', data.responseJSON);
  });

  $("#submit-role-modal-form").on('click', function(){
    $("form#user-role").trigger("submit");
  });

  function fetchTeachers(unity_id){
    var filter = { by_unity_id: unity_id };
    unity_id = String(unity_id);

    if(!_.isEmpty(unity_id)){

      $.ajax({
        url: Routes.teachers_pt_br_path({
            filter: filter,
            format: 'json'
        }),
        success: handleFetchTeachersSuccess,
        error: handleFetchTeachersError
      });
    }
  }

  function checkUnityType(unity_id){

    var filter = { by_unity_id: unity_id };
    unity_id = String(unity_id);

    if(!_.isEmpty(unity_id)){
      $.getJSON(Routes.unities_pt_br_path() + "/"+unity_id, function(data){
        if(data && data.unit_type == "school_unit"){
          $('#assumed-teacher-field').show();
          fetchTeachers(unity_id);
        }else{
          $('#assumed-teacher-field').hide();
        }
      });
    }
  }

  function handleFetchTeachersSuccess(data){
    var selectedTeachers = _.map(data, function(teacher) {
      return { id: teacher['id'], text: teacher['name'] };
    });

    insertEmptyElement(selectedTeachers);
    $('#user_assumed_teacher_id').select2({ formatResult: function(el) {
                                                    return "<div class='select2-user-result'>" + el.text + "</div>";
                                                  },
                                    data: selectedTeachers });
  }

  function handleFetchTeachersError(){
    flashMessages.error('Ocorreu um erro ao buscar os professores da unidade selecionada.');
  }

  function fetchClassroomsByTeacher(teacher_id){
    filter = { by_teacher_id: teacher_id };
    if(!_.isEmpty(teacher_id)){
      $.ajax({
        url: Routes.classrooms_pt_br_path({
            filter: filter,
            format: 'json'
        }),
        success: handleFetchClassroomsSuccess,
        error: handleFetchClassroomsError
      });
    }
  }

  function fetchClassroomsByTeacherAndUnity(teacher_id, unity_id){
    unity_id = String(unity_id);
    teacher_id = String(teacher_id);

    filter = { by_teacher_id: teacher_id, by_unity: unity_id };
    if(!_.isEmpty(teacher_id) && !_.isEmpty(unity_id)){
      $.ajax({
        url: Routes.classrooms_pt_br_path({
            filter: filter,
            format: 'json'
        }),
        success: handleFetchClassroomsSuccess,
        error: handleFetchClassroomsError
      });
    }
  }

  function handleFetchClassroomsSuccess(data){
    var selectedClassrooms = _.map(data, function(classroom) {
      return { id: classroom['id'], text: classroom['description'] };
    });

    insertEmptyElement(selectedClassrooms);
    $('#user_current_classroom_id').select2({ formatResult: function(el) {
                                                              return "<div class='select2-user-result'>" + el.text + "</div>";
                                                            },
                                              data: selectedClassrooms });
  }

  function handleFetchClassroomsError(){
    flashMessages.error('Ocorreu um erro ao buscar as turmas do professor selecionado.');
  }

  function fetchUnities(){
    $.ajax({
      url: Routes.search_unities_pt_br_path({
          format: 'json',
          per: 9999999
      }),
      success: handleFetchUnitiesSuccess,
      error: handleFetchUnitiessError
    });

  }

  function handleFetchUnitiesSuccess(data){
    var selectedUnities = _.map(data.unities, function(unity) {
      return { id: unity['id'], text: unity['name'] };
    });

    insertEmptyElement(selectedUnities);
    $('#user_current_unity_id').select2({ formatResult: function(el) {
                                                          return "<div class='select2-user-result'>" + el.text + "</div>";
                                                        },
                                          data: selectedUnities });
  }

  function handleFetchUnitiessError(){
    flashMessages.error('Ocorreu um erro ao buscar as escolas.');
  }

  $('#user_current_user_role_id').on('change', function(){
    $('#classroom-field').hide();
    $('#discipline-field').hide();
    $('#unity-field').hide();
    $('#assumed-teacher-field').hide();
    var user_role_id = $(this).select2('val');

    if(!_.isEmpty(user_role_id)){
      $.ajax({
        url: Routes.user_role_pt_br_path( user_role_id, {
            format: 'json'
        }),
        success: handleFetchRoleSuccess,
        error: handleFetchRoleError
      });
    }

    function handleFetchRoleSuccess(data){
      role_unity_id = data.user_role.unity_id;
      switch (data.user_role.role.access_level) {
        case 'administrator':
          toggleAdministratorFields();
          break;

        case 'employee':
          toggleEmployeeFields(data.user_role.unity_id);
          break;

        case 'teacher':
          toggleTeacherFields(data.user_role.unity_id);
          break;

        case 'parent':
        case 'student':
          toggleParentAndStudentFields();
          break;
      }
    }

    function handleFetchRoleError(){
      flashMessages.error('Ocorreu um erro ao buscar o nível de acesso da permissão selecionada.');
    }
  });

  $('#user_current_unity_id').on('change', function(){
    $('#assumed-teacher-field').hide();
    var unity_id = $(this).select2('val');
    $('#user_assumed_teacher_id').select2("val", '').trigger("change");
    checkUnityType(unity_id);
  });

  $('#user_assumed_teacher_id').on('change', function(){
    var teacher_id = $(this).val();

    $("#user_current_classroom_id").select2('val', '');
    $("#user_current_discipline_id").select2('val', '');

    if(teacher_id){
      $('#classroom-field').show();
      $('#discipline-field').show();
      var unity_id = role_unity_id ? role_unity_id : $("#user_current_unity_id").select2("val");
      fetchClassroomsByTeacherAndUnity(teacher_id, unity_id);
      fetchDisciplines();
    }else{
      $("#user_current_classroom_id").val('');
      $("#user_current_discipline_id").val('');
      $('#classroom-field').hide()
      $('#discipline-field').hide();
    }
  });

  function fetchDisciplines(){
    var classroom_id = $("#user_current_classroom_id").val();
    $('#user_current_discipline_id').select2('val', '');

    filter = { by_classroom: classroom_id };

    params = {
      filter: filter,
      format: 'json'
    }

    if($("#assumed-teacher-field").is(":visible") ||
          (!$("form#user-role").is(":visible") && $("#user_assumed_teacher_id").val().length ) ){
      filter.by_teacher_id = $("#user_assumed_teacher_id").select2("val");
    }else{
      params.use_user_teacher = true;
    }
    if(!_.isEmpty(classroom_id)){
      $.ajax({
        url: Routes.search_disciplines_pt_br_path(params),
        success: handleFetchDisciplinesSuccess,
        error: handleFetchDisciplinesError
      });
    }else{
      handleFetchDisciplinesSuccess({disciplines: [] });
    }
  }

  $('#user_current_classroom_id').on('change', fetchDisciplines);

  function handleFetchDisciplinesSuccess(data){
    var selectedDisciplines = _.map(data.disciplines, function(discipline) {
      return { id: discipline['id'], text: discipline['description'] };
    });

    insertEmptyElement(selectedDisciplines);
    $('#user_current_discipline_id').select2({ formatResult: function(el) {
                                                                return "<div class='select2-user-result'>" + el.text + "</div>";
                                                             },
                                               data: selectedDisciplines });
  }

  function handleFetchDisciplinesError(){
    flashMessages.error('Ocorreu um erro ao buscar as disciplinas da turma selecionada.');
  }

  $('#user_current_user_role_id').trigger('change');

  function toggleAdministratorFields(){
    $('#classroom-field').hide();
    $('#discipline-field').hide();

    $('#unity-field').show();

    if(!$("#user_current_unity_id").val().length){
      $("#user_assumed_teacher_id").val('');
      $("#user_current_classroom_id").val('');
      $("#user_current_discipline_id").val('');
    }

    $('#user_current_unity_id').trigger('change');
    $('#user_assumed_teacher_id').trigger('change');
    $('#user_current_classroom_id').trigger('change');

    fetchUnities();
  }

  function toggleEmployeeFields(unity_id){
    $('#classroom-field').hide();
    $('#discipline-field').hide();
    $('#unity-field').hide();

    $("#user_current_unity_id").val('');
    $("#user_current_classroom_id").val('');
    $("#user_current_discipline_id").val('');

    $('#assumed-teacher-field').show();

    $('#user_assumed_teacher_id').trigger('change');
    $('#user_current_classroom_id').trigger('change');

    fetchTeachers(unity_id);
  }

  function toggleTeacherFields(unity_id){
    $('#unity-field').hide();
    $('#assumed-teacher-field').hide();
    $("#user_assumed_teacher_id").val('');
    $("#user_current_unity_id").val('');

    $('#classroom-field').show();
    $('#discipline-field').show();

    $('#user_current_classroom_id').trigger('change');

    fetchClassroomsByTeacherAndUnity($('#user_teacher_id').val(), unity_id);
    fetchDisciplines();
  }

  function toggleParentAndStudentFields(){
    $("#user_current_tea_id").val('');
    $("#user_current_unity_id").val('');
    $("#user_current_unity_id").val('');
    $('#classroom-field').hide();
    $('#discipline-field').hide();
    $('#unity-field').hide();
    $('#assumed-teacher-field').hide();
  }

  function insertEmptyElement(elementArray){
    if(!_.isEmpty(elementArray)){
      elementArray.unshift({ id: "empty", text: "<option></option>" });
    }
  }
});

$.fn.render_form_errors = function(model_name, errors) {
  var form;
  form = this;
  this.clear_form_errors();
  return $.each(errors, function(field, messages) {
    var input;
    input = form.find('input, select, textarea').filter(function() {
      var name;
      name = $(this).attr('name');
      if (name) {
        return name.match(new RegExp(model_name + '\\[' + field + '\\(?'));
      }
    });
    input.closest('.control-group').addClass('error');
    return input.parent().append('<span class="help-inline">' + $.map(messages, function(m) {
      return m.charAt(0).toUpperCase() + m.slice(1);
    }).join('<br />') + '</span>');
  });
};

$.fn.clear_form_errors = function() {
  this.find('.control-group').removeClass('error');
  return this.find('span.help-inline').remove();
};

$.fn.clear_form_fields = function() {
  return this.find(':input', '#user-role').not(':button, :submit, :reset, :hidden').val('').removeAttr('checked').removeAttr('selected');
};
