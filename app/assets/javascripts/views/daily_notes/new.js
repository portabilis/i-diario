$(function () {
  "use strict";

  var $classroom = $("#daily_note_classroom_id"),
    $discipline = $("#daily_note_discipline_id"),
    $avaliation = $("#daily_note_avaliation_id"),
    $submitButton = $('input[type="submit"]'),
    flashMessages = new FlashMessages();

  toggleSubmitButton();

  $classroom.on("change", function (e) {
    if (!_.isEmpty(e.val)) {
      fetchDisciplines(e.val);
    } else {
      $discipline.select2({ data: [] });
    }
  });

  $avaliation.on("change", function () {
    toggleSubmitButton();
  });

  function fetchDisciplines(classroom_id) {
    $.ajax({
      url: Routes.disciplines_pt_br_path({
        classroom_id: classroom_id,
        format: "json",
      }),
      success: handleFetchDisciplinesSuccess,
      error: handleFetchDisciplinesError,
    });
  }

  function handleFetchDisciplinesSuccess(disciplines) {
    var selectedDisciplines = _.map(disciplines, function (discipline) {
      return {
        id: discipline["id"],
        text: discipline["description"],
      };
    });
    $discipline.select2({ data: selectedDisciplines });
  }

  function handleFetchDisciplinesError() {
    flashMessages.error(
      "Ocorreu um erro ao buscar as disciplinas da turma selecionada."
    );
  }

  function toggleSubmitButton() {
    if (!$avaliation.val()) {
      $submitButton.prop("disabled", true);
    } else {
      $submitButton.prop("disabled", false);
    }
  }
});
