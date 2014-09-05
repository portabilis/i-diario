window.Educacao = { Models: {}, Views: {}, Collections: {} };

Backbone.Marionette.Renderer.render = function (template, data) {
  if (_.isObject(template) && template.type === "handlebars") {
    return template.template(_.extend(data, template.data), template.options);
  }

  return template(data);
};
