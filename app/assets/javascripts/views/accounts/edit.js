$(function() {
  'use strict';

  var toggleUserReceiveNewsOptions = function(){
    if($("#user_receive_news").prop("checked")){
      $(".receive_news_options").show();
    }else{
      $(".receive_news_options").hide();
    }
  }
  $("#user_receive_news").on("change", toggleUserReceiveNewsOptions);
  toggleUserReceiveNewsOptions();

});
