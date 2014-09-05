var FlashMessages = function () {
  this.notifyOptions = {
    autoHide : true,
    clickOverlay : false,
    MinWidth : 250,
    TimeShown : 1000,
    ShowTimeEffect : 200,
    HideTimeEffect : 200,
    LongTrip :20,
    HorizontalPosition : 'center',
    VerticalPosition : 'top',
    ShowOverlay : false,
  }
};

FlashMessages.prototype.pop = function (message) {
  jNotify(message, this.notifyOptions);
};
