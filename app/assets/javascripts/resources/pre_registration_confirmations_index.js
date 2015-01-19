$(function () {
  $('#***REMOVED***_confirmations_search').submit(function () {  
    $.get(this.action, $(this).serialize(), null, 'script');  
    return false;  
  });  

  $('#***REMOVED***_confirmations_search .pagination a').on('click',   
    function () {  
      $.getScript(this.href);  
      return false;  
    }  
  ); 
});
