window["content_list_model_name"] = "knowledge_area_lesson_plan";
window["content_list_submodel_name"] = "lesson_plan";

$(function () {
  "use strict";
  var $classroom = $(
    "#knowledge_area_lesson_plan_lesson_plan_attributes_classroom_id"
  );
  var idContentsCounter = 1;

  const copyTeachingPlanLink = document.getElementById(
    "copy-from-teaching-plan-link"
  );
  const copyObjectivesTeachingPlanLink = document.getElementById(
    "copy-from-objectives-teaching-plan-link"
  );
  const startAtInput = document.getElementById(
    "knowledge_area_lesson_plan_lesson_plan_attributes_start_at"
  );
  const endAtInput = document.getElementById(
    "knowledge_area_lesson_plan_lesson_plan_attributes_end_at"
  );
  const knowledgeAreasInput = document.getElementById(
    "knowledge_area_lesson_plan_knowledge_area_ids"
  );
  const copyFromTeachingPlanAlert = document.getElementById(
    "lesson_plan_copy_from_teaching_plan_alert"
  );
  const copyFromObjectivesTeachingPlanAlert = document.getElementById(
    "lesson_plan_copy_from_objectives_teaching_plan_alert"
  );
  const flashMessages = new FlashMessages();
  const start_at = startAtInput.closest("div.control-group");
  const end_at = endAtInput.closest("div.control-group");

  // Função auxiliar para validações comuns
  const validateDateFields = () => {
    if (
      start_at.classList.contains("error") ||
      end_at.classList.contains("error")
    ) {
      flashMessages.error(
        "É necessário preenchimento das datas válidas para realizar a cópia."
      );
      return false;
    }
    return true;
  };

  const validateKnowledgeAreas = () => {
    if (!knowledgeAreasInput.value) {
      flashMessages.error(
        "É necessário preenchimento das áreas de conhecimento para realizar a cópia."
      );
      return false;
    }
    return true;
  };

  const validateDateInputs = () => {
    if (!startAtInput.value || !endAtInput.value) {
      flashMessages.error(
        "É necessário preenchimento das datas para realizar a cópia."
      );
      return false;
    }
    return true;
  };

  const performAllValidations = () => {
    return (
      validateDateFields() && validateKnowledgeAreas() && validateDateInputs()
    );
  };

  // Função auxiliar para criar elementos na lista
  const createListElement = (content, config) => {
    const selector = `li.list-group-item.active input[type=checkbox][data-${config.dataAttribute}="${content.description}"]`;

    if (!$(selector).length) {
      const newLine = JST[config.template]({
        id: content.id,
        description: content.description,
        model_name: window["content_list_model_name"],
        submodel_name: window["content_list_submodel_name"],
      });

      $(config.targetList).append(newLine);
      $(".list-group.checked-list-box .list-group-item:not(.initialized)").each(
        initializeListEvents
      );
    }
  };

  // Função auxiliar para preenchimento de listas
  const fillDataList = (data, config) => {
    if (data.knowledge_area_lesson_plans.length) {
      data.knowledge_area_lesson_plans.forEach((content) =>
        createListElement(content, config)
      );
    } else {
      config.alertElement.style.display = "block";
    }
  };

  // Função auxiliar para criar handler de tags
  const createTagsHandler = (selector, config) => {
    $(selector).on("change", function (e) {
      if (e.val.length) {
        var uniqueId = "customId_" + idContentsCounter++;
        var description = e.val.join(", ");

        if (
          description.trim().length &&
          !$(
            `input[type=checkbox][data-${config.dataAttribute}="${description}"]`
          ).length
        ) {
          var html = JST[config.template]({
            id: uniqueId,
            description: description,
            model_name: "knowledge_area_lesson_plan",
            submodel_name: "lesson_plan",
          });

          $(config.targetList).append(html);
          $(
            ".list-group.checked-list-box .list-group-item:not(.initialized)"
          ).each(initializeListEvents);
        } else {
          var input = $(
            `input[type=checkbox][data-${config.dataAttribute}="${description}"]`
          );
          input.closest("li").show();
          input.prop("checked", true).trigger("change");
        }

        $(config.clearSelector).val("");
      }
      $(this).select2("val", "");
    });
  };

  // Função auxiliar para criar event listeners de cópia
  const createCopyEventListener = (linkElement, config) => {
    if (linkElement) {
      linkElement.addEventListener("click", (event) => {
        if (!performAllValidations()) {
          return false;
        }

        event.preventDefault();
        config.alertElement.style.display = "none";

        const params = {
          classroom_id: $classroom.val(),
          knowledge_area_ids: knowledgeAreasInput.value,
          start_date: startAtInput.value,
          end_date: endAtInput.value,
        };

        $.getJSON(config.url, params).done((data) =>
          fillDataList(data, config)
        );
        return false;
      });
    }
  };

  // Configurações para contents
  const contentsConfig = {
    dataAttribute: "content_description",
    template: "templates/layouts/contents_list_manual_item",
    targetList: "#contents-list",
    clearSelector:
      ".knowledge_area_lesson_plan_lesson_plan_contents_tags .select2-input",
    alertElement: copyFromTeachingPlanAlert,
    url: Routes.teaching_plan_contents_knowledge_area_lesson_plans_pt_br_path(),
  };

  // Configurações para objectives
  const objectivesConfig = {
    dataAttribute: "objective_description",
    template: "templates/layouts/objectives_list_manual_item",
    targetList: "#objectives-list",
    clearSelector:
      ".knowledge_area_lesson_plan_lesson_plan_objectives_tags .select2-input",
    alertElement: copyFromObjectivesTeachingPlanAlert,
    url: Routes.teaching_plan_objectives_knowledge_area_lesson_plans_pt_br_path(),
  };

  // Aplicando os handlers
  createTagsHandler(
    "#knowledge_area_lesson_plan_lesson_plan_attributes_contents_tags",
    contentsConfig
  );
  createTagsHandler(
    "#knowledge_area_lesson_plan_lesson_plan_attributes_objectives_tags",
    objectivesConfig
  );

  // Criando event listeners para cópia
  createCopyEventListener(copyTeachingPlanLink, contentsConfig);
  createCopyEventListener(copyObjectivesTeachingPlanLink, objectivesConfig);

  if ($("#action_name").val() == "show") {
    $(".list-group.checked-list-box .list-group-item").each(function () {
      $(this).off("click");
    });
  }
});

$(function () {
  $("textarea[maxLength]").maxlength();

  const fields = [
    "activities",
    "resources",
    "evaluation",
    "bibliography",
    "curriculum_adaptation",
  ];

  fields.forEach((field) => {
    createSummerNote(
      `textarea[id^=knowledge_area_lesson_plan_lesson_plan_attributes_${field}]`,
      {
        toolbar: [["font", ["bold", "italic", "underline", "clear"]]],
      }
    );
  });
});
