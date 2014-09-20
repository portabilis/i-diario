Educacao.Views.Students = Backbone.Marionette.CompositeView.extend({
  template: {
    type: "handlebars",
    template: HandlebarsTemplates["signup/students"]
  },

  childView: Educacao.Views.Student,

  childViewContainer: "tbody"
});
