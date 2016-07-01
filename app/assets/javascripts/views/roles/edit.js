$(function(){
  "use strict";

  showCurrentRoleInfo()

  $('#role_access_level').on('change', function(){
    showCurrentRoleInfo();
  });

  function showCurrentRoleInfo(){
    hideAllRoleInfos();
    switch($('#role_access_level').select2('val')){
      case 'administrator':
        $('#administrator-role-info').show();
        break;
      case 'employee':
        $('#employee-role-info').show();
        break;
      case 'teacher':
        $('#teacher-role-info').show();
        break;
      case 'parent':
        $('#parent-role-info').show();
        break;
      case 'student':
        $('#student-role-info').show();
        break;
    }
  }

  function hideAllRoleInfos(){
    $('#administrator-role-info').hide();
    $('#employee-role-info').hide();
    $('#teacher-role-info').hide();
    $('#parent-role-info').hide();
    $('#student-role-info').hide();
  }
});
