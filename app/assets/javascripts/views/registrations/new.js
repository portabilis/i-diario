$(function() {
  'use strict';

  var $signupParentRole = $('#signup_parent_role');
  var $signupParentRoleContainer = $('div.well-parent-role');
  var $signupStudentRole = $('#signup_student_role');
  var $signupStudentRoleContainer = $('div.well-student-role');
  var $signupEmployeeRole = $('#signup_employee_role');
  var $signupEmployeeRoleContainer = $('div.well-employee-role');

  $signupParentRoleContainer.on('click', function() {
    var parentRoleChecked = $signupParentRole.prop('checked');
    $signupParentRole.prop('checked', !parentRoleChecked)
  });

  $signupStudentRoleContainer.on('click', function() {
    var studentRoleChecked = $signupStudentRole.prop('checked');
    $signupStudentRole.prop('checked', !studentRoleChecked)
  });

  $signupEmployeeRoleContainer.on('click', function() {
    var employeeRoleChecked = $signupEmployeeRole.prop('checked');
    $signupEmployeeRole.prop('checked', !employeeRoleChecked)
  });
});
