$(function() {
  $("#survey_invitation_modal").modal("show");
  $("#survey_invitation_link").on("click", function(){
    $("#survey_invitation_modal").modal("hide");
  });
});