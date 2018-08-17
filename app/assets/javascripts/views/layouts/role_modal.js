$(function(){
   "use strict";

  var role_unity_id = null;
  var flashMessages = new FlashMessages();
  $("form#user-role").on("ajax:success", function(event, data, status, xhr){
    $("form#user-role").clear_form_fields();
    $("form#user-role").clear_form_errors();
    if($('#current_action_').val() == 'edit'){
      location.href = Routes.root_pt_br_path;
    }else{
      location.reload();
    }
    }).on("ajax:error", function(event, data, status, xhr){
      $("form#user-role").render_form_errors('user', data.responseJSON);
  });

  $("#role-modal").on('shown.bs.modal', function(){
    $('form#user-role #user_current_user_role_id').val(window.user.current_user_role_id);
    $('form#user-role #user_current_unity_id').val(window.user.current_unity_id);
    $('form#user-role #user_assumed_teacher_id').val(window.user.assumed_teacher_id);
    $('form#user-role #user_current_classroom_id').val(window.user.current_classroom_id);
    $('form#user-role #user_current_discipline_id').val(window.user.current_discipline_id);
    $('form#user-role #user_current_user_role_id').trigger("change");
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
            find_by_current_year: true,
            format: 'json'
        }),
        success: handleFetchTeachersSuccess,
        error: handleFetchTeachersError
      });
    }
  }

  function handleFetchTeachersSuccess(data){
    var selectedTeachers = _.map(data, function(teacher) {
      return { id: teacher['id'], text: teacher['name'] };
    });

    insertEmptyElement(selectedTeachers);
    $('form#user-role #user_assumed_teacher_id').select2({ formatResult: function(el) {
                                                    return "<div class='select2-user-result'>" + el.text + "</div>";
                                                  },
                                    data: selectedTeachers });
    if(_.isNull($('form#user-role #user_assumed_teacher_id').select2("data"))){
      $('form#user-role #user_assumed_teacher_id').val("");
      $('#classroom-field').hide();
      $('#discipline-field').hide();
    }
  }

  function handleFetchTeachersError(){
    flashMessages.error('Ocorreu um erro ao buscar os professores da unidade selecionada.');
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

  function fetchClassroomsByTeacher(teacher_id){
    filter = { by_teacher_id: teacher_id };
    if(!_.isEmpty(teacher_id)){
      $.ajax({
        url: Routes.classrooms_pt_br_path({
            filter: filter,
            find_by_current_year: true,
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

    var filter = { by_teacher_id: teacher_id, by_unity: unity_id };
    if(!_.isEmpty(teacher_id) && !_.isEmpty(unity_id)){
      $.ajax({
        url: Routes.classrooms_pt_br_path({
            filter: filter,
            find_by_current_year: true,
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

    if(_.isEmpty(selectedClassrooms)){
      $('form#user-role #user_current_classroom_id').val("");
    }

    insertEmptyElement(selectedClassrooms);
    $('form#user-role #user_current_classroom_id').select2({ formatResult: function(el) {
                                                              return "<div class='select2-user-result'>" + el.text + "</div>";
                                                            },
                                              data: selectedClassrooms });
    fetchDisciplines();
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

    if(_.isEmpty(selectedUnities)){
      $('form#user-role #user_current_unity_id').val("");
    }

    insertEmptyElement(selectedUnities);
    $('form#user-role #user_current_unity_id').select2({ formatResult: function(el) {
                                                          return "<div class='select2-user-result'>" + el.text + "</div>";
                                                        },
                                          data: selectedUnities });
  }

  function handleFetchUnitiessError(){
    flashMessages.error('Ocorreu um erro ao buscar as escolas.');
  }

  $('form#user-role #user_current_user_role_id').on('change', function(){

    var user_role_id = $(this).val();

    if(_.isEmpty(user_role_id)){
      $('#no-role-selected-alert').removeClass('hidden');
    }else{
      $('#no-role-selected-alert').addClass('hidden');
    }

    if(valueSelected($(this))){
      $.ajax({
        url: Routes.user_role_pt_br_path( user_role_id, {
            format: 'json'
        }),
        success: handleFetchRoleSuccess,
        error: handleFetchRoleError
      });
    }else{
      toggleNoProfileSelectedFields();
    }

    function handleFetchRoleSuccess(data){
      role_unity_id = null;
      switch (data.user_role.role.access_level) {
        case 'administrator':
          toggleAdministratorFields();
          break;

        case 'employee':
          toggleEmployeeFields(data.user_role.unity_id);
          role_unity_id = data.user_role.unity_id;
          break;

        case 'teacher':
          toggleTeacherFields(data.user_role.unity_id);
          role_unity_id = data.user_role.unity_id;
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

  $('form#user-role #user_current_unity_id').on('change', function(){
    $('#assumed-teacher-field').hide();
    $('#classroom-field').hide();
    $('#discipline-field').hide();

    var unity_id = $(this).val();

    fetchTeachers(unity_id);
    checkUnityType(unity_id);

    var emptyElements = insertEmptyElement([]);

    $('form#user-role #user_assumed_teacher_id').select2("data", emptyElements);
    $('form#user-role #user_current_classroom_id').select2("data", emptyElements);
    $('form#user-role #user_current_discipline_id').select2("data", emptyElements);
  });

  $('form#user-role #user_assumed_teacher_id').on('change', function(){
    var teacher_id = $(this).val();

    if(valueSelected($(this))){
      $('#classroom-field').show();
      $('#discipline-field').show();
      var unity_id = role_unity_id ? role_unity_id : $("form#user-role #user_current_unity_id").val();
      fetchClassroomsByTeacherAndUnity(teacher_id, unity_id);
    }else{
      $("form#user-role #user_current_classroom_id").val('');
      $("form#user-role #user_current_discipline_id").val('');
      $('#classroom-field').hide();
      $('#discipline-field').hide();
    }
  });

  $('form#user-role #user_current_classroom_id').on('change', fetchDisciplines);

  function fetchDisciplines(){
    var classroom_id = $("form#user-role #user_current_classroom_id").val();
    var filter = { by_classroom: classroom_id };
    var params = {
      filter: filter,
      format: 'json'
    }

    if($("#assumed-teacher-field").is(":visible") ||
          (!$("form#user-role").is(":visible") && $("form#user-role #user_assumed_teacher_id").val().length ) ){
      filter.by_teacher_id = $("form#user-role #user_assumed_teacher_id").val();
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
      var selectedDisciplines = [];
      insertEmptyElement(selectedDisciplines);
      $('form#user-role #user_current_discipline_id').select2({ formatResult: function(el) {
                                                                  return "<div class='select2-user-result'>" + el.text + "</div>";
                                                               },
                                                 data: selectedDisciplines });
    }
  }

  function handleFetchDisciplinesSuccess(data){
    var selectedDisciplines = _.map(data.disciplines, function(discipline) {
      return { id: discipline['id'], text: discipline['description'] };
    });

    if(_.isEmpty(selectedDisciplines)){
      $('form#user-role #user_current_discipline_id').val("");
    }

    insertEmptyElement(selectedDisciplines);
    $('form#user-role #user_current_discipline_id').select2({ formatResult: function(el) {
                                                                return "<div class='select2-user-result'>" + el.text + "</div>";
                                                             },
                                               data: selectedDisciplines });
  }

  function handleFetchDisciplinesError(){
    flashMessages.error('Ocorreu um erro ao buscar as disciplinas da turma selecionada.');
  }

  // Togglers
  function toggleNoProfileSelectedFields(){

    $("form#user-role #user_current_teacher_id").val('');
    $("form#user-role #user_current_unity_id").val('');
    $("form#user-role #user_current_classroom_id").val('');
    $("form#user-role #user_current_discipline_id").val('');

    $('#assumed-teacher-field').hide();
    $('#unity-field').hide();
    $('#classroom-field').hide();
    $('#discipline-field').hide();
  }

  function toggleAdministratorFields(){
    $('#classroom-field').hide();
    $('#discipline-field').hide();
    $('#assumed-teacher-field').hide();

    $('#unity-field').show();

    fetchUnities();
    if(valueSelected($('form#user-role #user_current_unity_id'))){
      $('#assumed-teacher-field').show();
      fetchTeachers($('form#user-role #user_current_unity_id').val());
      checkUnityType($('form#user-role #user_current_unity_id').val());

      if(valueSelected($('form#user-role #user_assumed_teacher_id'))){
        $('#discipline-field').show();
        $('#classroom-field').show();
        fetchClassroomsByTeacherAndUnity($('form#user-role #user_assumed_teacher_id').val(), $('form#user-role #user_current_unity_id').val());
      }
    }
  }

  function toggleEmployeeFields(unity_id){
    $('#unity-field').hide();
    $('#classroom-field').hide();
    $('#discipline-field').hide();

    $('#assumed-teacher-field').show();

    $("form#user-role #user_current_unity_id").val('');

    fetchTeachers(unity_id);

    if(valueSelected($('form#user-role #user_assumed_teacher_id'))){
      $('#discipline-field').show();
      $('#classroom-field').show();
      fetchClassroomsByTeacherAndUnity($('form#user-role #user_assumed_teacher_id').val(), unity_id);
    }
  }

  function toggleTeacherFields(unity_id){
    $('#unity-field').hide();
    $('#assumed-teacher-field').hide();

    $("form#user-role #user_assumed_teacher_id").val('');
    $("form#user-role #user_current_unity_id").val('');

    $('#classroom-field').show();
    $('#discipline-field').show();

    fetchClassroomsByTeacherAndUnity($('form#user-role #user_teacher_id').val(), unity_id);

  }

  function toggleParentAndStudentFields(){
    $("form#user-role #user_current_teacher_id").val('');
    $("form#user-role #user_current_unity_id").val('');

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

  function valueSelected(select2Element){
    return !(_.isEmpty(select2Element.val()) || select2Element.val() == 0);
  }
});

$.fn.clear_form_fields = function() {
  return this.find(':input', '#user-role').not(':button, :submit, :reset, :hidden').val('').removeAttr('checked').removeAttr('selected');
};
