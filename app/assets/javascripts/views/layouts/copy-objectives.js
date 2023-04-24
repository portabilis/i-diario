document.addEventListener('DOMContentLoaded', () => {
  'use strict';
  // alert('copy-objectives.js loaded');
  const confirmCopyButton = document.getElementById('confirm-copy-objectives-modal');
  const experienceConfirmButton = document.getElementById('experience-confirm-btn');
  const disciplinesConfirmCopyButton = document.getElementById('disciplines-confirm-btn');

  // console.log(confirmCopyButton);
  const requestContents = (itens, origin) => {
    return new Promise(resolve => {
      const url = Routes.contents_learning_objectives_and_skills_pt_br_path();
      let params = {}

      if (origin === 'experience') {
        params[experienceConfirmButton.dataset.type] = itens
      } else if (origin === 'disciplines') {
        params[disciplinesConfirmCopyButton.dataset.type] = itens
      } else {
        params[confirmCopyButton.dataset.type] = itens
      }

      $.getJSON(url, params).done(resolve);
    });
  };

  const addElement = (description) => {
    if(!$('li.list-group-item.active input[type=checkbox][data-objective_description="'+description+'"]').length) {
      const newLine = JST['templates/layouts/objectives_list_manual_item']({
        description: description,
        model_name: window['content_list_model_name'],
        submodel_name: window['content_list_submodel_name']
      });

      $('#objectives-list').append(newLine);
      $('.list-group.checked-list-box .list-group-item:not(.initialized)').each(initializeListEvents);
    }
  };

  const checkedExperienceFields = () => {
    return document.querySelectorAll('[name="experience_fields[]"]:checked');
  };

  const copyObjectives = () => {
    const selectedItens = [];


    $(checkedExperienceFields()).each(function() {
      const experience_field = this.dataset.id;
      const grades = $(this).closest('.row').find('input.grade_ids').select2("val");
      selectedItens.push({ type: experience_field, grades: grades });
    });

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

  const disciplinesCopyObjectives = () => {
    const selectedItens = [];


    $(checkedExperienceFields()).each(function() {
      const experience_field = this.dataset.id;
      const grades = $(this).closest('.row').find('input.grade_ids').select2("val");
      selectedItens.push({ type: experience_field, grades: grades });
    });

    if (selectedItens.length === 0) {
      return;
    }

    requestContents(selectedItens, 'disciplines').then(data => {
      data['contents'].forEach(content => {
        addElement(content['description']);
      });

      $('#disciplines-modal').modal('hide');
    });
  };

  const experienceCopyObjectives = () => {
    const selectedItens = [];


    $(checkedExperienceFields()).each(function() {
      const experience_field = this.dataset.id;
      const grades = $(this).closest('.row').find('input.grade_ids').select2("val");
      selectedItens.push({ type: experience_field, grades: grades });
    });

    if (selectedItens.length === 0) {
      return;
    }

    requestContents(selectedItens, 'experience').then(data => {
      data['contents'].forEach(content => {
        addElement(content['description']);
      });

      $('#experience-modal').modal('hide');
    });
  };

  if (confirmCopyButton) {
    confirmCopyButton.addEventListener('click', copyObjectives);
  }

  if (experienceConfirmButton) {
    experienceConfirmButton.addEventListener('click', experienceCopyObjectives);
  }

  if (disciplinesConfirmCopyButton) {
    disciplinesConfirmCopyButton.addEventListener('click', disciplinesCopyObjectives);
  }

  const clearCheckboxs = () => {
    checkedExperienceFields().forEach(checkboxInput => {
      checkboxInput.checked = false;
    });
  };

  const clearGrades = () => {
    $('.grades').hide();
    $('input.grade_ids').select2("val", "");
  };

  $('[name="experience_fields[]"]').change(function() {
    if ($(this).is(':checked')) {
      $(this).closest('.row').find('.grades').show();
    } else {
      $(this).closest('.row').find('.grades').hide();
      $(this).closest('.row').find('input.grade_ids').select2("val", "");
    }
  });

  $('#copy-objectives-modal').on('show.bs.modal', function() {
    clearCheckboxs();
    clearGrades();
  });

  $('#disciplines-modal').on('show.bs.modal', function() {
    clearCheckboxs();
    clearGrades();
  });

  $('#experience-modal').on('show.bs.modal', function() {
    clearCheckboxs();
    clearGrades();
  });
});
