$.fn.render_form_errors = function(model_name, errors) {
  var form;
  form = this;
  this.clear_form_errors();
  return $.each(errors, function(field, messages) {
    var input;
    input = form.find('input, select, textarea').filter(function() {
      var name;
      name = $(this).attr('name');
      if (name) {
        return name.match(new RegExp(model_name + '\\[' + field + '\\(?'));
      }
    });
    input.closest('.control-group').addClass('error');
    return input.parent().append('<span class="help-inline">' + $.map(messages, function(m) {
      return m.charAt(0).toUpperCase() + m.slice(1);
    }).join('<br />') + '</span>');
  });
};

$.fn.clear_form_errors = function() {
  this.find('.control-group').removeClass('error');
  return this.find('span.help-inline').remove();
};
