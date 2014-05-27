window.Backbone.ServerErrorsPresenter = function(view, customMapping) {
  this.viewEl = view.$el;
  this.customMapping = _.isUndefined(customMapping) ? {} : customMapping;
};

Backbone.ServerErrorsPresenter.prototype.isOneError = function () {
  return _.isString(this.errors);
};

Backbone.ServerErrorsPresenter.prototype.showErrorInField = function (key, error) {
  if (this.customMapping[key]) {
    key = this.customMapping[key];
  }

  var control = this.viewEl.find("[name=" + key + "]");
  var group = control.parents(".control-group");

  group.addClass("error");

  group.find(".controls").
    append("<span class=\"help-inline error-message\">" + error + "</span>");
};

Backbone.ServerErrorsPresenter.prototype.cleanPreviousErrors = function () {
  this.viewEl.find(".control-group").removeClass("error");
  this.viewEl.find(".error-message").remove();
};

Backbone.ServerErrorsPresenter.prototype.present = function (errors, cleanPreviousErrors) {
  if (cleanPreviousErrors !== false) {
    this.cleanPreviousErrors();
  }

  this.errors = _.isUndefined(errors["error"]) ? errors["errors"] : errors["error"];

  if (this.isOneError()) {
    this.showErrorInAlert(this.errors);
  } else {
    this.presentMultipleErrors();
  }
};

Backbone.ServerErrorsPresenter.prototype.presentMultipleErrors = function () {
  _.each(this.errors, function (error, key) {
    if (key != "base") {
      this.showErrorInField(key, error[0]);
    }
  }, this);
};
