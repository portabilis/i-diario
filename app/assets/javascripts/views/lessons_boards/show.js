$(function() {
  $("#print-button").on("click", function() {
    let clone = $("#lessons-board-table").clone();

    clone.find("input:not([type='hidden'])").each(function() {
      let value = $(this).val();
      $(this).replaceWith(`<span>${value}</span>`);
    });

    clone.find("input[type='hidden']").remove();

    clone.printThis({
      pageTitle: "Quadro de Aulas",
      header:
        "<table class='table table-bordered'><thead><tr>" +
        "<th>ESCOLA</th><th>Série</th><th>Turma</th><th>Período</th></tr><tr>" +
        "<th>" +
        $("#lessons_board_unity").val() +
        "</th>" +
        "<th>" +
        $("#lessons_board_grade").val() +
        "</th>" +
        "<th>" +
        $("#lessons_board_classroom_id").val() +
        "</th>" +
        "<th>" +
        $("#lessons_board_period").val() +
        "</th></tr>" +
        "</thead></table>"
    });
  });
});
