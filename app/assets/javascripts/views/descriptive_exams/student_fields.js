$(function () {
  $('textarea[maxLength]').maxlength();

  $("textarea[id^=descriptive_exam_students_attributes_]").summernote({
    lang: 'pt-BR',
    toolbar: [
      ['font', ['bold', 'italic', 'underline', 'clear']],
    ],
    disableDragAndDrop : true
  });
});
