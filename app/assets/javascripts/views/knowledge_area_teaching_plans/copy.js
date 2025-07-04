$(document).ready(function () {
  function handleSelectAll(buttonId, inputId, clearButtonId) {
    $(buttonId).click(function () {
      const elements = $(inputId).attr("data-elements");
      const ids = JSON.parse(elements)
        .map((item) => item.id)
        .filter(Number.isInteger);

      $(inputId).val(ids.join(",")).trigger("change");

      $(clearButtonId).show();
      $(buttonId).hide();
    });
  }

  function handleClear(buttonId, inputId, selectAllButtonId) {
    $(buttonId).click(function () {
      $(inputId).val("").trigger("change");

      $(buttonId).hide();
      $(selectAllButtonId).show();
    });
  }

  handleSelectAll(
    "#all-unities",
    "#copy_knowledge_area_teaching_plan_form_unities_ids",
    "#clear-unities"
  );

  handleClear(
    "#clear-unities",
    "#copy_knowledge_area_teaching_plan_form_unities_ids",
    "#all-unities"
  );

  handleSelectAll(
    "#all-grades",
    "#copy_knowledge_area_teaching_plan_form_grades_ids",
    "#clear-grades"
  );

  handleClear(
    "#clear-grades",
    "#copy_knowledge_area_teaching_plan_form_grades_ids",
    "#all-grades"
  );
});
