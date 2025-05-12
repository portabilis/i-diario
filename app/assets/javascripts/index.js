$(function(){
  $('.apply_tooltip').tooltip({ placement: 'left'});
  $('.apply_tooltip_right').tooltip({ placement: 'right'});

  // Regular expression for dd/mm/yyyy date including validation for leap year and more
  var dateRegex = '^(?:(?:31(\\/)(?:0?[13578]|1[02]))\\1|(?:(?:29|30)(\\/)(?:0?[1,3-9]|1[0-2])\\2))(?:(?:1[6-9]|[2-9]\\d)?\\d{2})$|^(?:29(\\/)0?2\\3(?:(?:(?:1[6-9]|[2-9]\\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00))))$|^(?:0?[1-9]|1\\d|2[0-8])(\\/)(?:(?:0?[1-9])|(?:1[0-2]))\\4(?:(?:1[6-9]|[2-9]\\d)?\\d{2})$';
  var typingTimer;
  var doneTypingInterval = 1000;

  var filterableSearch = function(e) {
    var dateFields = $('form.filterable_search_form input.datepicker');
    var breakOut = false;

    $(dateFields).each(function(){
      if(this.value != '' && _.isEmpty(this.value.match(dateRegex))){
        breakOut = true;

        return false;
      }
    });

    if(breakOut){
      return false;
    }

    clearTimeout(typingTimer);

    $.get(
      $('form.filterable_search_form').attr('action'),
      $('form.filterable_search_form').serialize(),
      null,
      'script'
    );

    return false;
  }

  $('form.filterable_search_form').submit(filterableSearch);

  $('.remote .pagination a').on('click',
    function() {
      var onPageChange = new CustomEvent('onPageChange');
      document.dispatchEvent(onPageChange);

      $.getScript(this.href);
      return false;
    }
  );

  $('form.filterable_search_form input:not(.autocomplete, .select2-input)').keyup(function(e) {
    clearTimeout(typingTimer);
    typingTimer = setTimeout(function() {
      filterableSearch(e);
    }, doneTypingInterval);
  });

  $('form.filterable_search_form input:not(.autocomplete, .select2-input)').keydown(function() {
    clearTimeout(typingTimer);
  });

  $('form.filterable_search_form select, form.filterable_search_form input.select2, input.select2_remote,\
     form.filterable_search_form input.select2_step, form.filterable_search_form input.datepicker,\
     form.filterable_search_form input.select2_plans'
  ).on('change', filterableSearch);
})
