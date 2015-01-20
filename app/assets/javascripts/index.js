$(function(){
  $('.apply_tooltip').tooltip({ placement: 'left'});

  var typingTimer;              
  var doneTypingInterval = 500;

  var filterableSearch = function(){
    clearTimeout(typingTimer);
    $.get($('form.filterable_search_form').attr('action'), 
      $('form.filterable_search_form').serialize(), null, 'script');    
    return false;    
  }

  $('form.filterable_search_form').submit(filterableSearch);  

  $('form.filterable_search_form .pagination a').on('click',   
    function () {  
      $.getScript(this.href);  
      return false;  
    }  
  );  

  $('form.filterable_search_form input').keyup(function(){
      clearTimeout(typingTimer);
      typingTimer = setTimeout(filterableSearch, doneTypingInterval);
  });

  $('form.filterable_search_form input').keydown(function(){
      clearTimeout(typingTimer);
  });

  $('form.filterable_search_form select').on('change', filterableSearch);

})