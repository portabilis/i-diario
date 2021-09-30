$(document).ready(function () {
  $('#all-unities').click(function () {
    let unities;

    unities = $("#copy_discipline_teaching_plan_form_unities_ids").attr('data-elements');
    unities = JSON.parse(unities);
    unities = unities.map(function (unity) {
      return unity.id;
    });
    unities = unities.filter(function (id) {
      return Number.isInteger(id);
    });

    $("#copy_discipline_teaching_plan_form_unities_ids").val(unities.join(','));
    $("#copy_discipline_teaching_plan_form_unities_ids").trigger('change');

    $('#clear-unities').show();
    $('#all-unities').hide();
  });

  $('#clear-unities').click(function () {
    $("#copy_discipline_teaching_plan_form_unities_ids").val('');
    $("#copy_discipline_teaching_plan_form_unities_ids").trigger('change');

    $('#clear-unities').hide();
    $('#all-unities').show();
  });

  $('#all-grades').click(function () {
    let grades;

    grades = $("#copy_discipline_teaching_plan_form_grades_ids").attr('data-elements');
    grades = JSON.parse(grades);
    grades = grades.map(function (grade) {
      return grade.id;
    });
    grades = grades.filter(function (id) {
      return Number.isInteger(id);
    });

    $("#copy_discipline_teaching_plan_form_grades_ids").val(grades.join(','));
    $("#copy_discipline_teaching_plan_form_grades_ids").trigger('change');

    $('#clear-grades').show();
    $('#all-grades').hide();
  });

  $('#clear-grades').click(function () {
    $("#copy_discipline_teaching_plan_form_grades_ids").val('');
    $("#copy_discipline_teaching_plan_form_grades_ids").trigger('change');

    $('#clear-grades').hide();
    $('#all-grades').show();
  });
});
