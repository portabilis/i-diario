//= require_tree ./signup/models
//= require_tree ./signup/views

$(function () {
  $('form#signup-parent').on('change', '#signup_document, #signup_student_code', function () {
    var $document = $('#signup_document').val().replace(/[^0-9+]/g, ''),
        $studentCode = $('#signup_student_code').val();

    window.studentsRegion = new Backbone.Marionette.Region({
      el: '#students'
    });

    if ($document.length != 0 && $studentCode.length != 0) {
      var students = new Educacao.Collections.Students();

      students.fetch({
        data: { document: $document, student_code: $studentCode },
        success: function (students) {
          var student = students.findWhere({ aluno_id: $studentCode });
          student.set('selected', true);

          window.studentsRegion.show(new Educacao.Views.Students({ collection: students }));

          $('a[href=#tab2]').click();
        },
        error: function (model, response) {
          console.log(response.responseText);
        }
      });
    }
  });

  $('#signup-wizard').bootstrapWizard({
    'tabClass': 'form-wizard'
  });
});
