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
        var thisNote = $(this);
        var updatePastedText = function(someNote){
          var original = someNote.summernote('code');
          var cleaned = CleanPastedHTML(original);

          someNote.summernote('reset');
          someNote.summernote('pasteHTML', cleaned);

        };

        setTimeout(function () {
          //the function is called after the text is really pasted.
          updatePastedText(thisNote);
      }, 10);
      }
    }
  });

  function CleanPastedHTML(input) {
    // 1. remove line breaks / Mso classes
    var stringStripper = /(\n|\r| class=(")?Mso[a-zA-Z]+(")?)/g;
    var output = input.replace(stringStripper, ' ');
    // 2. strip Word generated HTML comments
    var commentSripper = new RegExp('<!--(.*?)-->','g');
    var output = output.replace(commentSripper, '');
    var tagStripper = new RegExp('<(/)*(meta|link|span|\\?xml:|st1:|o:|font)(.*?)>','gi');
    // 3. remove tags leave content if any
    output = output.replace(tagStripper, '');
    // 4. Remove everything in between and including tags '<style(.)style(.)>'
    var badTags = ['style', 'script','applet','embed','noframes','noscript'];

    for (var i=0; i< badTags.length; i++) {
      tagStripper = new RegExp('<'+badTags[i]+'.*?'+badTags[i]+'(.*?)>', 'gi');
      output = output.replace(tagStripper, '');
    }
    // 5. remove attributes ' style="..."'
    var badAttributes = ['style', 'start'];
    for (var i=0; i< badAttributes.length; i++) {
      var attributeStripper = new RegExp(' ' + badAttributes[i] + '="(.*?)"','gi');
      output = output.replace(attributeStripper, '');
    }
    return output;
  }
});
