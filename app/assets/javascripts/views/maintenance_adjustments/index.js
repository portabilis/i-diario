$(() => {
  "use strict";

  let checkPendingStatusPath = `${location.protocol}//${location.host}${location.pathname}/any_completed`;

  let checkPendingStatusSuccess = (data) => {
    if (data.any_completed) {
      $('form.filterable_search_form').trigger('submit');
    }
  }

  let getPendingIds = () => $('[data-column=situation][data-value=pending]').map((key, element)=> $(element).data('id')).toArray();

  let checkPendingStatus = () => {
    let pendingIds = getPendingIds();
    if (pendingIds.length === 0) {
      return false;
    }

    $.ajax({
      url: checkPendingStatusPath,
      success: checkPendingStatusSuccess,
      beforeSend: ()=>{},
      complete: ()=>{
        setTimeout(checkPendingStatus, 2000);
      },
      data: {
        ids: pendingIds
      }
    })
  };

  setTimeout(checkPendingStatus, 2000);
});