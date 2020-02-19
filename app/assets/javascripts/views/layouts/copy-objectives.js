document.addEventListener('DOMContentLoaded', () => {
  'use strict';

  const confirmCopyButton = document.getElementById('confirm-copy-objectives-modal');

  const requestContents = (itens) => {
    return new Promise(resolve => {
      const url = Routes.contents_learning_objectives_and_skills_pt_br_path();
      let params = {}
      params[confirmCopyButton.dataset.type] = itens

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

  const checkedExperienceFields = () => {
     return document.querySelectorAll('[name="experience_fields[]"]:checked');
  };

  const copyObjectives = () => {
    const selectedItens = Array.from(checkedExperienceFields()).map(element => element.dataset.id);
    if (selectedItens.length === 0) {
      return;
    }

    requestContents(selectedItens).then(data => {
      data['contents'].forEach(content => {
        addElement(content['description']);
      });

      $('#copy-objectives-modal').modal('hide');
    });
  };

  confirmCopyButton.addEventListener('click', copyObjectives);

  const clearCheckboxs = () => {
    checkedExperienceFields().forEach(checkboxInput => {
      checkboxInput.checked = false;
    });
  };

  $('#copy-objectives-modal').on('show.bs.modal', clearCheckboxs);
});
