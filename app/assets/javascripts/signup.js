//= require_tree ./signup/models
//= require_tree ./signup/views

$(function () {
  var $validator = $("#signup-parent").validate({
    highlight: function (element) {
      $(element).closest('.form-group').removeClass('has-success').addClass('has-error');
    },
    unhighlight: function (element) {
      $(element).closest('.form-group').removeClass('has-error').addClass('has-success');
    },
    errorElement: 'span',
    errorClass: 'help-block',
    errorPlacement: function (error, element) {
      if (element.parent('.input-group').length) {
        error.insertAfter(element.parent());
      } else {
        error.insertAfter(element);
      }
    }
  });

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

          if (students.length < 1) {
            $('#students-quantity').hide();
          }

          $('a[href=#tab2]').click();
        },
        error: function (model, response) {
          console.log(response.responseText);
        }
      });
    }
  });

  $('#signup-wizard').bootstrapWizard({
    'tabClass': 'form-wizard',
    'onNext': function (tab, navigation, index) {
      var $valid = $("#signup-parent").valid();
      if (!$valid) {
        $validator.focusInvalid();
        return false;
      } else {
        $('#signup-wizard').find('.form-wizard').children('li').eq(index - 1).addClass('complete');
        $('#signup-wizard').find('.form-wizard').children('li').eq(index - 1).find('.step')
        .html('<i class="fa fa-check"></i>');
      }
    }
  });
});
