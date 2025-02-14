// Ao remover esse arquivo remover tambem o plugin printThis
$(function() {
  $("#print-button ").on("click", function() {
    $("#lessons-board-table").printThis({
      pageTitle: "Quadro de Aulas",
      header:
        "<table class='table table-bordered'><thead<tr>" +
        "<th style='width: 40px;'>ESCOLA</th>" +
        "<th style='width: 40px;'>Série</th>" +
        "<th style='width: 40px;'>Turma</th>" +
        "<th style='width: 40px;'>Periodo</th></tr><tr>" +
        "<th style='width: 40px;'>" +
        $("#lessons_board_unity").val() +
        "</th>" +
        "<th style='width: 40px;'>" +
        $("#lessons_board_grade").val() +
        "</th>" +
        "<th style='width: 40px;'>" +
        $("#lessons_board_classroom_id").val() +
        "</th>" +
        "<th style='width: 40px;'>" +
        $("#lessons_board_period").val() +
        "</th></tr>" +
        "<thead></table>"
    });
  });
});
