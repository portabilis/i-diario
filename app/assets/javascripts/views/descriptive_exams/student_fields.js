$(function () {
  // Seleciona os textareas com o atributo readonly
  $("textarea[readonly]").each(function () {
    createSummerNote(this, {
      toolbar: [
        ['font', ['bold', 'italic', 'underline', 'clear']],
      ],
      disabled: true
    });
  });

  $('textarea[maxLength]').maxlength();

  createSummerNote("textarea[id^=descriptive_exam_students_attributes_]", {
    toolbar: [
      ['font', ['bold', 'italic', 'underline', 'clear']],
    ]
  });
});
