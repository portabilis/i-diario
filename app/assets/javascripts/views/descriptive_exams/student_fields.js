$(function () {
  $('textarea[maxLength]').maxlength();

  createSummerNote("textarea[id^=descriptive_exam_students_attributes_]", {
    toolbar: [
      ['font', ['bold', 'italic', 'underline', 'clear']],
    ]
  })
});
