document.addEventListener('DOMContentLoaded', () => {
  const stepInput = document.getElementById('learning_objectives_and_skill_step');
  const stepRelatedContainers = document.querySelectorAll('form .only-child-school, .only-elementary-school');
  const onlyChildSchool = document.querySelectorAll('form .only-child-school');
  const onlyElementarySchool = document.querySelectorAll('form .only-elementary-school');
  const hideContainer = container => container.style.display = 'none';
  const showContainer = container => container.style.display = 'block';

  const checkStepRelatedVisibility = () => {
    stepRelatedContainers.forEach(hideContainer);

    if (stepInput.value == 'child_school') {
      onlyChildSchool.forEach(showContainer);
      $("#learning_objectives_and_skill_elementary_educations").select2("data", "");
      $("#learning_objectives_and_skill_discipline").select2("data", "");
      $("#learning_objectives_and_skill_thematic_unit").val("");
    }

    if (stepInput.value == 'elementary_school') {
      onlyElementarySchool.forEach(showContainer);
      $("#learning_objectives_and_skill_child_educations").select2("data", "");
      $("#learning_objectives_and_skill_field_of_experience").select2("data", "");
    }
  };

  // select2 doesnt fire javascript event, only jquery event
  $(stepInput).on('change', checkStepRelatedVisibility);

  checkStepRelatedVisibility();
});
