function createSummerNote(element, options = {}) {
  $(element).summernote({
    lang: 'pt-BR',
    toolbar: options.toolbar || [],
    disableDragAndDrop : true,
    height: 300,
    width: 600,
    callbacks : {
      onPaste : function (event) {
        var thisNote = $(this);
        var updatePastedText = function(someNote){
          var original = someNote.summernote('code');
          var cleaned = CleanPastedHTML(original);

          someNote.summernote('code', cleaned);
        };

        setTimeout(function () {
          updatePastedText(thisNote);
        }, 10);
      }
    }
  });

  if (options.disabled) {
    $(element).each(function(index, el) {
      $(el).summernote('disable');
    })
  }
}

function CleanPastedHTML(input) {
  var stringStripper = /(\n|\r| class=(")?Mso[a-zA-Z]+(")?)/g;
  var output = input.replace(stringStripper, ' ');
  var commentSripper = new RegExp('<!--(.*?)-->','g');
  var output = output.replace(commentSripper, '');
  var tagStripper = new RegExp('<(/)*(meta|link|span|\\?xml:|st1:|o:|font)(.*?)>','gi');
  output = output.replace(tagStripper, '');
  var badTags = getTags(output)
  for (var i=0; i< badTags.length; i++) {
    tagStripper = new RegExp('<'+badTags[i]+'.*?'+badTags[i]+'(.*?)>', 'gi');
    output = output.replace(tagStripper, '');
  }
  var badAttributes = ['style', 'start'];
  for (var i=0; i< badAttributes.length; i++) {
    var attributeStripper = new RegExp(' ' + badAttributes[i] + '="(.*?)"','gi');
    output = output.replace(attributeStripper, '');
  }

  return output;
}

function getTags(htmlString){
  var tmpTag = document.createElement("div");
  tmpTag.innerHTML = htmlString;

  var all = tmpTag.getElementsByTagName("*");
  var goodTags = ['DIV', 'P', 'B', 'I', 'U', 'BR'];
  var tags = [];

  for (var i = 0, max = all.length; i < max; i++) {
    var tagname = all[i].tagName;

    if (tags.indexOf(tagname) == -1 && !goodTags.includes(tagname)) {
      tags.push(tagname);
    }
  }

  return tags
}
