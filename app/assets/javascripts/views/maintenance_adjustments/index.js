$(function() {
  "use strict";

  var checkPendingStatusPath = location.protocol + '//' + location.host + location.pathname + '/any_completed';

  var checkPendingStatusSuccess = function(data) {
    if (data.any_completed) {
      $('form.filterable_search_form').trigger('submit');
    }
  };

  var getPendingIds = function() {
    return $('[data-column=situation][data-value=pending]').map(function(key, element) { return $(element).data('id') }).toArray();
  }

  var checkPendingStatus = function(){
    var pendingIds = getPendingIds();
    if (pendingIds.length === 0) {
      setTimeout(checkPendingStatus, 2000);
      return false;
    }

    $.ajax({
      url: checkPendingStatusPath,
      success: checkPendingStatusSuccess,
      beforeSend: function(){},
      complete: function(){
        setTimeout(checkPendingStatus, 2000);
      },
      data: {
        ids: pendingIds
      }
    })
  };

  setTimeout(checkPendingStatus, 2000);
});