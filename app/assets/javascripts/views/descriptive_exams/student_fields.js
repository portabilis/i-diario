$(function () {
  $('textarea[maxLength]').maxlength();

  $("textarea[id^=descriptive_exam_students_attributes_]").summernote({
    lang: 'pt-BR',
    toolbar: [
      ['font', ['bold', 'italic', 'underline', 'clear']],
    ],
    disableDragAndDrop : true,
    callbacks : {
      onPaste : function (event) {
        event.preventDefault();

        let text = null;

        if (window.clipboardData){
          text = window.clipboardData.getData("Text");
        } else if (event.originalEvent && event.originalEvent.clipboardData){
          text = event.originalEvent.clipboardData.getData("Text");
        }

        $(this).summernote('insertText', text);
        $(this).val(text);
      }
    }
  });
});
