document.addEventListener('DOMContentLoaded', () => {
  'use strict';

  const requestContents = (experienceFields) => {
    return new Promise(resolve => {
      const url = Routes.contents_learning_objectives_and_skills_pt_br_path();
      const params = {
        experience_fields: experienceFields
      };

      $.getJSON(url, params).done(resolve);
    });
  };

  const addElement = (description) => {
    if(!$('li.list-group-item.active input[type=checkbox][data-content_description="'+description+'"]').length) {
      const newLine = JST['templates/layouts/contents_list_manual_item']({
        description: description,
        model_name: window['content_list_model_name'],
        submodel_name: window['content_list_submodel_name']
      });

      $('#contents-list').append(newLine);
      $('.list-group.checked-list-box .list-group-item:not(.initialized)').each(initializeListEvents);
    }
  };

  const copyObjectives = () => {
    const selectedCheckboxs = document.querySelectorAll('[name="experience_fields[]"]:checked');
    const selectedExperienceFields = Array.from(selectedCheckboxs).map(element => element.dataset.id);
    if (selectedExperienceFields.length === 0) {
      return;
    }

    requestContents(selectedExperienceFields).then(data => {
      data['contents'].forEach(content => {
        addElement(content['description']);
      });

      $('#copy-objectives-modal').modal('hide');
    });
  };

  document.getElementById('confirm-copy-objectives-modal').addEventListener('click', copyObjectives);
});
