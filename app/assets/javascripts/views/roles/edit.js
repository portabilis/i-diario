$(function(){
  "use strict";

  var $rolePermissionsTbody = $("#role-permissions-tbody");

  $('#role_access_level').on('change', function(){
    showCurrentRoleInfo();
  });

  var removeFeaturesNotIncluded = function (access_level){
    $rolePermissionsTbody.find('tr.nested-fields:not([data-level-'+access_level+'])').each(function(){
      $(this).hide().find('input.select2[id$=_permission]').select2('val', 'denied');
    });
  }

  var showIncludedFeatures = function (access_level){
    $rolePermissionsTbody.find('tr.nested-fields[data-level-'+access_level+']').each(function(){
      $(this).show();
    });
  }

  function showCurrentRoleInfo(){
    hideAllRoleInfos();
    var access_level = $('#role_access_level').select2('val');

    if(access_level.length){
      $("#"+access_level+"-role-info").show();
      removeFeaturesNotIncluded(access_level);
      showIncludedFeatures(access_level);
    }
  }

  function hideAllRoleInfos(){
    $('#administrator-role-info').hide();
    $('#employee-role-info').hide();
    $('#teacher-role-info').hide();
    $('#parent-role-info').hide();
    $('#student-role-info').hide();
  }

  showCurrentRoleInfo()
});
