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
  var school_term_type_id = schoolTermType.select2('val');
  $schoolTermType = schoolTermType;
  $schoolTerm = schoolTerm;
  $schoolTermContainer = schoolTermContainer;
  $flashMessages = flashMessagesParam;
  selectedSchoolTermTypeId = $('#yearly_school_term_type_id').val();
  isSchoolTermIdValid = school_term_type_id.trim() &&
                        school_term_type_id.trim() != selectedSchoolTermTypeId &&
                        school_term_type_id.trim() != '2'; // 2 is the value for 'Anual' in the select2

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
