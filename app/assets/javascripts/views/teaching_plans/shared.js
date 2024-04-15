var $schoolTermType, $schoolTerm, $schoolTermContainer, flashMessages;

function handleFetchSchoolTermTypeStepsSuccess(data){
  var steps = _.map(data.school_term_type_steps, function(school_term_type_steps) {
    return { id: school_term_type_steps.id, text: school_term_type_steps.description };
  });

  $schoolTerm.select2({ data: steps });
  $schoolTermContainer.show();
}

function handleFetchSchoolTermTypeStepsError() {
  flashMessages.error('Ocorreu um erro ao buscar as etapas');
  $schoolTerm.val('');
  $schoolTermContainer.hide();
};

function updateSchoolTermInput(schoolTermType, schoolTerm, schoolTermContainer, flashMessagesParam) {
  school_term_type_id = schoolTermType.select2('val').trim();
  selectedData = schoolTermType.select2('data')
  school_term_type_data = selectedData ? selectedData.name : null;
  selectedSchoolTermTypeId = $('#yearly_school_term_type_id').val();

  $schoolTermType = schoolTermType;
  $schoolTerm = schoolTerm;
  $schoolTermContainer = schoolTermContainer;
  $flashMessages = flashMessagesParam;

  let isSchoolTermIdValid = school_term_type_data != null &&
    school_term_type_id != selectedSchoolTermTypeId &&
    school_term_type_data != 'Anual (1 etapa)';

  if (isSchoolTermIdValid) {
    $.ajax({
      url: Routes.steps_by_school_term_type_id_pt_br_path({
        school_term_type_id: school_term_type_id,
        format: 'json'
      }),
      success: handleFetchSchoolTermTypeStepsSuccess,
      error: handleFetchSchoolTermTypeStepsError
    });
  } else {
    schoolTerm.val('');
    schoolTermContainer.hide();
  }
}
