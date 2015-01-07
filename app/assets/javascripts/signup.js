//= require_tree ./signup/models
//= require_tree ./signup/views

$(function () {
  var userWithoutStudents = function () {
    var $studentCode = $('#signup_student_code'),
        $studentsContainer = $('#students-container');

    if ($('#signup_without_student').prop('checked')) {
      $studentCode.val('').prop('disabled', 'disabled');
      $studentsContainer.hide();
    } else {
      $studentCode.prop('disabled', false);
      $studentsContainer.show();
    }
  };

  userWithoutStudents();

  $('#signup_without_student').on('click', function () {
    userWithoutStudents();
  });

  if ($("table#students tbody tr").length <= 1) {
    $('#students-quantity').hide();
  }

  $('form#signup-parent').on('change', '#signup_document, #signup_student_code', function () {
    var $document = $('#signup_document').val().replace(/[^0-9+]/g, ''),
        $studentCode = $('#signup_student_code').val();

    window.studentsRegion = new Backbone.Marionette.Region({
      el: '#students'
    });

    if ($document.length != 0 && $studentCode.length != 0) {
      var students = new Educacao.Collections.Students();
      var apiErrors = $('#api-errors');
      var $studentsQuantity = $('#students-quantity');
      var withoutStudent = $('#signup_without_student').prop('checked');

      if (withoutStudent) {
        return true;
      }

      apiErrors.addClass("hide");

      students.fetch({
        data: { document: $document, student_code: $studentCode },
        success: function (students) {
          var student = students.findWhere({ aluno_id: $studentCode });
          student.set('selected', true);

          window.studentsRegion.show(new Educacao.Views.Students({ collection: students }));

          if (students.length < 1) {
            $studentsQuantity.hide();
          } else {
            $studentsQuantity.show();
          }

          $('a[href=#tab2]').click();
        },
        error: function (model, response) {
          apiErrors.removeClass("hide");
          apiErrors.find("span").html(response.responseText);
        }
      });
    }
  });
});
