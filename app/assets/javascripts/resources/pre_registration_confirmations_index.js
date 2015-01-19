$(function () {

  var typingTimer;              
  var doneTypingInterval = 500;

  var preRegistrationConfirmationSearch = function(){
    clearTimeout(typingTimer);
    $.get($('#***REMOVED***_confirmations_search').attr('action'), 
      $('#***REMOVED***_confirmations_search').serialize(), null, 'script');    
    return false;    
  }

  $('#***REMOVED***_confirmations_search').submit(preRegistrationConfirmationSearch);  

  $('#***REMOVED***_confirmations_search .pagination a').on('click',   
    function () {  
      $.getScript(this.href);  
      return false;  
    }  
  );  

  $('#***REMOVED***_confirmations_search input').keyup(function(){
      clearTimeout(typingTimer);
      typingTimer = setTimeout(preRegistrationConfirmationSearch, doneTypingInterval);
  });

  $('#***REMOVED***_confirmations_search input').keydown(function(){
      clearTimeout(typingTimer);
  });

  $('#***REMOVED***_confirmations_search select').on('change', preRegistrationConfirmationSearch);

});
