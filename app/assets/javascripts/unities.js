//= require ./unities/model
//= require ./unities/view

if ($("#unity-region").length == 1) {
  window.flashMessages = new FlashMessages();

  window.unityRegion = new Backbone.Marionette.Region({
    el: "#unity-region"
  });

  var unity = new Educacao.Models.Unity(window.unityData);

  window.unityRegion.show(new Educacao.Views.UnityBase({ model: unity }));
}
