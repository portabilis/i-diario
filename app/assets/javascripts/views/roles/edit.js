$(function(){
  "use strict";

  hideAllRoleInfos();

  $('#role_access_level').on('change', function(){
    hideAllRoleInfos();
    switch($(this).select2('val')){
      case 'institutional':
        $('#institutional-role-info').show();
        break;
      case 'unit':
        $('#unit-role-info').show();
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
  });

  function hideAllRoleInfos(){
    $('#institutional-role-info').hide();
    $('#unit-role-info').hide();
    $('#teacher-role-info').hide();
    $('#parent-role-info').hide();
    $('#student-role-info').hide();
  }
});
