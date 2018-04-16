$(function() {
  $('#custom_rounding_table_course_ids').change(function() {
    var filter = {
      by_courses: $(this).val()
    };

    $.ajax({
      url: Routes.grades_pt_br_path({
        filter: filter,
        format: 'json'
      }),
      success: handleFetchGradesSuccess,
      error: handleFetchGradesError
    });
  });

  function handleFetchGradesSuccess(data) {
    var grades = [];

    if ($('#custom_rounding_table_course_ids').val() != '') {
      grades = _.map(data, function(grade) {
        return { id: grade.id, text: grade.description };
      });
    }

    var select2_grades = $('#custom_rounding_table_grade_ids');
    select2_grades.select2('val', '');
    select2_grades.select2({ data: grades, multiple: true });
  };

  function handleFetchGradesError() {
    flashMessages.error('Ocorreu um erro ao buscar as séries dos cursos selecionados.');
  };

  $('input[id$=action]').change(function() {
    if($(this).val() == '3') {
      $(this).closest('tr').find('input[id$=exact_decimal_place]').removeAttr('readonly');
    } else {
      $(this).closest('tr').find('input[id$=exact_decimal_place]').attr('readonly', true).val('');
    }
  });

  $('input[id$=action]').trigger('change');
});
