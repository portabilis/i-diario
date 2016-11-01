$(function () {
  'use strict';

  var flashMessages = new FlashMessages();
  var $classroom = $('#partial_score_record_report_form_classroom_id');
  var $student = $('#partial_score_record_report_form_student_id');

  function fetchStudents() {
    var classroom_id = $classroom.select2('val');

    $student.select2('val', '');
    $student.select2({ data: [] });

    if (!_.isEmpty(classroom_id)) {

      $.ajax({
        url: Routes.students_pt_br_path({
          classroom_id: classroom_id,
          format: 'json'
        }),
        success: fetchStudentsSuccess,
        error: fetchStudentsError
      });
    }
  };
  $classroom.on('change', fetchStudents);

  function fetchStudentsSuccess(data) {
    var students = _.map(data.students, function(student) {
      return { id: student.id, text: student.name };
    });

    $student.select2({ data: students });
  };

  function fetchStudentsError() {
    flashMessages.error('Ocorreu um erro ao buscar os alunos!')
  };

});
