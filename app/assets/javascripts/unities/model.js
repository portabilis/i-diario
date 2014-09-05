Educacao.Models.Unity = Backbone.Model.extend({
  urlRoot: '/unities',

  defaults: {
    name: "",
    email: "",
    phone: "",
    api_code: "",
    responsible: ""
  }
});
