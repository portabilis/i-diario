Educacao.Views.Student = Backbone.Marionette.ItemView.extend({
  template: {
    type: "handlebars",
    template: HandlebarsTemplates["signup/student"]
  },

  ui :{
    selectStudent: 'input.select-student'
  },

  tagName: "tr",

  className: "nested-fields",

  onRender: function () {
    this.ui.selectStudent.prop('checked', this.model.get('selected'));
  },

  serializeData: function () {
    return _.extend(
      this.model.toJSON(),
      {
        api_code: this.model.get('aluno_id'),
        name: this.model.get('nome_aluno'),
        cid: this.model.cid,
        selected: this.model.get('selected')
      }
    )
  }
});
