Educacao.Views.UnityBase = Backbone.Marionette.LayoutView.extend({
  template: {
    type: "handlebars",
    template: HandlebarsTemplates["unities/form"]
  },

  ui: {
    commitButton: "#commit",
    name: "#name",
    email: "#email",
    phone: "#phone",
    apiCode: "#api_code",
    responsible: "#responsible"
  },

  triggers: {
    "click @ui.commitButton": "save"
  },

  events: {
    "change input": "changeData"
  },

  initialize: function () {
    this.serverErrorsPresenter = new window.ServerErrorsPresenter(this.$el, "unity");
  },

  changeData: function () {
    this.model.set({
      name: this.ui.name.val(),
      email: this.ui.email.val(),
      phone: this.ui.phone.val(),
      api_code: this.ui.apiCode.val(),
      responsible: this.ui.responsible.val()
    });
  },

  onSave: function () {
    var that = this;

    var isNew = this.model.isNew();

    this.model.save({}, {
      nested: true,
      disableButton: this.ui.commitButton,
      success: function () {
        that.serverErrorsPresenter.cleanPrevious();

        if (isNew) {
          that.clear();
        } else {
          window.flashMessages.pop("Unidade editada com sucesso");
        }
      },
      error: function (model, xhr) {
        that.serverErrorsPresenter.present(xhr.responseJSON);
      }
    });
  },

  clear: function () {
    window.flashMessages.pop("Unidade criada com sucesso");
  }
});
