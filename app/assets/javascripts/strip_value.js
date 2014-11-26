var StripValue = window.StripValue = function (fields, options) {
  this.fields = $(fields);
  this.options = options || {};

  this.setup();
  this.addEventLIstener();
};

StripValue.prototype.setup = function() {
  $.fn.caret = function(begin, end) {
    if (this.length == 0) return;
    if (typeof begin == 'number') {
      end = (typeof end == 'number') ? end : begin;
      return this.each(function() {
        if (this.setSelectionRange) {
          this.focus();
          this.setSelectionRange(begin, end);
        } else if (this.createTextRange) {
          var range = this.createTextRange();
          range.collapse(true);
          range.moveEnd('character', end);
          range.moveStart('character', begin);
          range.select();
        }
      });
    } else {
      if (this[0].setSelectionRange) {
        begin = this[0].selectionStart;
        end = this[0].selectionEnd;
      } else if (document.selection && document.selection.createRange) {
        var range = document.selection.createRange();
        begin = 0 - range.duplicate().moveStart('character', -100000);
        end = begin + range.text.length;
      }
      return { begin: begin, end: end };
    }
  };
};

StripValue.prototype.addEventLIstener = function() {
  var event = $.proxy(this.stripValueEvent, this);

  this.fields
    .on("load", event)
    .on("focus", event)
    .on("keypress", event)
    .on("keyup", event);
};

StripValue.prototype.stripValue = function(value) {
  var value = value || '';
  return value
           .toString()
           .replace(/[ÁÀÂÃÄ]/g, 'A')
           .replace(/[áàâãä]/g, 'a')
           .replace(/[ÉÈÊË]/g,  'E')
           .replace(/[éèêë]/g,  'e')
           .replace(/[ÍÌÎÏ]/g,  'I')
           .replace(/[íìîï]/g,  'i')
           .replace(/[ÓÒÔÕÖ]/g, 'O')
           .replace(/[óòôõö]/g, 'o')
           .replace(/[ÚÙÛÜ]/g,  'U')
           .replace(/[úùûü]/g,  'u')
           .replace(/[Ñ]/g,     'N')
           .replace(/[ñ]/g,     'n')
           .replace(/[Ç]/g,     'C')
           .replace(/[ç]/g,     'c');
};

StripValue.prototype.stripValueEvent = function(event){
  var element = $(event.target)
    , pos = element.caret()
    , value = element.val();

  element.val(this.stripValue(value));
  element.caret(pos.begin, pos.end); // Esta funcionalidade é dependência do maskinput
};

$.fn.strip = function (options) {
  new StripValue(this, options);
}
