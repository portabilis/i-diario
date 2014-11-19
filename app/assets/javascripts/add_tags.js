var AddTags = function() {
  var module = {};
  var $html, tags;

  var attachTagToEmailTarget = function(value) {
    var textAreaField = $html.find('#tag-receptor .note-editable');
    var actualFieldValue = textAreaField.html();

    textAreaField.html(actualFieldValue + " " + value);
  };

  var attachTagToSmsTarget = function(value) {
    var textAreaField = $html.find('#tag-receptor textarea');
    var actualFieldValue = textAreaField.val();

    textAreaField.focus().val(actualFieldValue + " " + value);
  };

  var attachTagClickEvent = function() {
    tags.on("click", function () {
      var tag = $(this).find('code').html();

      if ($html.find('.note-editable').length != 0) {
        attachTagToEmailTarget(tag);
      } else {
        attachTagToSmsTarget(tag);
      }
    });
  };

  module.init = function(html) {
    $html = $(html);
    tags = $html.find('.tags tr');

    attachTagClickEvent();
  };

  return module;
};
