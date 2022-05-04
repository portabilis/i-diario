var FlashMessages = function() {
  this.$container = $('#flash-messages');
};

FlashMessages.prototype.pop = function(message) {
  this.$container.html(message);
};

FlashMessages.prototype.success = function(message) {
  this.pop("<div class='alert alert-success'><i class='fa-fw fa fa-check'></i> " + message + "</div>");
};

FlashMessages.prototype.warning = function(message) {
  this.pop("<div class='alert alert-warning'><i class='fa-fw fa fa-warning'></i> " + message + "</div>");
};

FlashMessages.prototype.error = function(message) {
  this.pop("<div class='alert alert-danger'><i class='fa-fw fa fa-times'></i> " + message + "</div>");
};

FlashMessages.prototype.info = function(message) {
  this.pop("<div class='alert alert-info'><i class='fa-fw fa fa-info'></i> " + message + "</div>");
};
