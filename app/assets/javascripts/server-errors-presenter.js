window.ServerErrorsPresenter = function(viewEl, prefix) {
  this.viewEl = viewEl;
  this.prefix = (prefix || null);
  this.errorClass = "state-error";
};

ServerErrorsPresenter.prototype = {
  present: function (errors, options) {
    options = (options || { cleanPreviousErrors: true });
    errors = (errors || {});

    if (options.cleanPreviousErrors) {
      this.cleanPrevious();
    }

    this.presentErrors(errors);
  },

  presentErrors: function (errors) {
    _.each(errors.errors, function (error, key) {
      if (key == "base") { return; }
      this.showErrorInField(key, error[0]);
    }, this);
  },

  showErrorInField: function (key, error) {
    if (this.prefix) {
      key = this.prefix + "[" + key + "]";
    }

    var control = this.viewEl.find("[name='" + key + "']"),
        group = control.parents(".control-group");

    group.addClass(this.errorClass);

    group.
      find(".controls").
      append("<span class=\"help-inline error-message note\">" + error + "</span>");
  },

  cleanPrevious: function () {
    this.viewEl.find(".control-group").removeClass(this.errorClass);
    this.viewEl.find(".error-message").remove();
  }
};
