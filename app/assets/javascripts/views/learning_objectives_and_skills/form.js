document.addEventListener('DOMContentLoaded', () => {
  const stepInput = document.getElementById('learning_objectives_and_skill_step');
  const stepRelatedContainers = document.querySelectorAll('form .only-child-school, .only-elementary-school');
  const onlyChildSchool = document.querySelectorAll('form .only-child-school');
  const onlyElementarySchool = document.querySelectorAll('form .only-elementary-school');
  const hideContainer = container => container.style.display = 'none';
  const showContainer = container => container.style.display = 'block';
  var grades_elementary_educations = $("#learning_objectives_and_skill_elementary_educations"),
  disciplines = $("#learning_objectives_and_skill_discipline"),
  thematic_unit = $("#learning_objectives_and_skill_thematic_unit"),
  grades_child_educations = $("#learning_objectives_and_skill_thematic_unit"),
  field_of_experience = $("#learning_objectives_and_skill_field_of_experience")


  const checkStepRelatedVisibility = () => {
    stepRelatedContainers.forEach(hideContainer);
    step = stepInput.value

    if (step == 'child_school') {
      onlyChildSchool.forEach(showContainer);
      grades_elementary_educations.select2("data", "");
      disciplines.select2("data", "");
      thematic_unit.val("");
    }

    if (step == 'elementary_school' || step == 'adult_and_youth_education') {
      onlyElementarySchool.forEach(showContainer);
      grades_child_educations.select2("data", "");
      field_of_experience.select2("data", "");

      if (step == 'adult_and_youth_education') {
        return $.ajax({
          url: Routes.fetch_grades_learning_objectives_and_skills_pt_br_path({
            step: step,
            format: 'json'
          }),
          success: handleFetchGradesSuccess,
          error: handleFetchGradesError
        });
      }
    }
  };

  function handleFetchGradesSuccess(data){
    if (!_.isArray(data)) {
      grades_elementary_educations.val(null).trigger('change');

      let grades = data['learning_objectives_and_skills']

      grades_elementary_educations.select2({
        data: grades
      });
    }
  }

  function handleFetchGradesError(){

  }

  // select2 doesnt fire javascript event, only jquery event
  $(stepInput).on('change', checkStepRelatedVisibility);

  checkStepRelatedVisibility();
});
