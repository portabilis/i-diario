$(function () {

  var typingTimer;              
  var doneTypingInterval = 500;

  var preRegistrationSearch = function(){
    clearTimeout(typingTimer);
    $.get($('#***REMOVED***s_search').attr('action'), 
      $('#***REMOVED***s_search').serialize(), null, 'script');    
    return false;    
  }

  $('#***REMOVED***s_search').submit(preRegistrationSearch);  

  $('#***REMOVED***s_search .pagination a').on('click',   
    function () {  
      $.getScript(this.href);  
      return false;  
    }  
  );  

  $('#***REMOVED***s_search input').keyup(function(){
      clearTimeout(typingTimer);
      typingTimer = setTimeout(preRegistrationSearch, doneTypingInterval);
  });

  $('#***REMOVED***s_search input').keydown(function(){
      clearTimeout(typingTimer);
  });

  $('#***REMOVED***s_search select').on('change', preRegistrationSearch);

});
