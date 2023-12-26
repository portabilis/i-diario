document.addEventListener('DOMContentLoaded', () => {
  const stepInput = document.getElementById('learning_objectives_and_skill_step');
  const stepRelatedContainers = document.querySelectorAll('form .only-child-school, .only-elementary-school');
  const onlyChildSchool = document.querySelectorAll('form .only-child-school');
  const onlyElementarySchool = document.querySelectorAll('form .only-elementary-school');
  const hideContainer = container => container.style.display = 'none';
  const showContainer = container => container.style.display = 'block';
  var $grades = $("#learning_objectives_and_skill_grades"),
  disciplines = $("#learning_objectives_and_skill_discipline"),
  thematic_unit = $("#learning_objectives_and_skill_thematic_unit"),
  field_of_experience = $("#learning_objectives_and_skill_field_of_experience")

  const checkStepRelatedVisibility = () => {
    stepRelatedContainers.forEach(hideContainer);
    step = stepInput.value

    if (step == 'child_school') {
      onlyChildSchool.forEach(showContainer);
      disciplines.select2("data", "");
      thematic_unit.val("");
    }

    if (step == 'elementary_school' || step == 'adult_and_youth_education') {
      onlyElementarySchool.forEach(showContainer);
      field_of_experience.select2("data", "");
    }
  };

  function fetchGrades(step) {
    if (!_.isEmpty(step)) {
      $.ajax({
        url: Routes.fetch_grades_learning_objectives_and_skills_pt_br_path({
          step: step,
          format: 'json'
        }),
        success: handleFetchGradesSuccess,
        error: handleFetchGradesError
      });
    }
  };

  function handleFetchGradesSuccess(data){
    if (!_.isArray(data)) {
      $grades.val(null).trigger('change');

      let options = data['learning_objectives_and_skills']
      $grades.select2({
        data: options,
        multiple: true
      });
    }
  }

  function handleFetchGradesError(){
    flashMessages.error('Ocorreu um erro ao buscar as séries da etapa selecionada.');
  }

  // select2 doesnt fire javascript event, only jquery event
  $(stepInput).on('change', function (e) {
    var step = e.target.value;

    checkStepRelatedVisibility();
    fetchGrades(step)
  });

  checkStepRelatedVisibility();
});
