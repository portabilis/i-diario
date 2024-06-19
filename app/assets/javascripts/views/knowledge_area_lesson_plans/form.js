window['content_list_model_name'] = 'knowledge_area_lesson_plan';
window['content_list_submodel_name'] = 'lesson_plan';

$(function () {
  'use strict';
  var $classroom = $('#knowledge_area_lesson_plan_lesson_plan_attributes_classroom_id');
  var idContentsCounter = 1;

  const copyTeachingPlanLink = document.getElementById('copy-from-teaching-plan-link');
  const copyObjectivesTeachingPlanLink = document.getElementById('copy-from-objectives-teaching-plan-link');
  const startAtInput = document.getElementById('knowledge_area_lesson_plan_lesson_plan_attributes_start_at');
  const endAtInput = document.getElementById('knowledge_area_lesson_plan_lesson_plan_attributes_end_at');
  const knowledgeAreasInput = document.getElementById('knowledge_area_lesson_plan_knowledge_area_ids');
  const copyFromTeachingPlanAlert = document.getElementById('lesson_plan_copy_from_teaching_plan_alert');
  const copyFromObjectivesTeachingPlanAlert = document.getElementById(
    'lesson_plan_copy_from_objectives_teaching_plan_alert'
  );
  const flashMessages = new FlashMessages();
  const start_at = startAtInput.closest('div.control-group');
  const end_at = endAtInput.closest('div.control-group');

  $('#knowledge_area_lesson_plan_lesson_plan_attributes_contents_tags').on('change', function (e) {
    if (e.val.length) {

      var uniqueId = 'customId_' + idContentsCounter++;
      var content_description = e.val.join(", ");
      if (content_description.trim().length &&
        !$('input[type=checkbox][data-content_description="' + content_description + '"]').length) {

        var html = JST['templates/layouts/contents_list_manual_item']({
          id: uniqueId,
          description: content_description,
          model_name: 'knowledge_area_lesson_plan',
          submodel_name: 'lesson_plan'
        });

        $('#contents-list').append(html);
        $('.list-group.checked-list-box .list-group-item:not(.initialized)').each(initializeListEvents);
      } else {
        var content_input = $('input[type=checkbox][data-content_description="' + content_description + '"]');
        content_input.closest('li').show();
        content_input.prop('checked', true).trigger('change');
      }

      $('.knowledge_area_lesson_plan_lesson_plan_contents_tags .select2-input').val("");
    }
    $(this).select2('val', '');
  });

  $('#knowledge_area_lesson_plan_lesson_plan_attributes_objectives_tags').on('change', function (e) {
    if (e.val.length) {

      var uniqueId = 'customId_' + idContentsCounter++;
      var objective_description = e.val.join(", ");
      if (objective_description.trim().length &&
        !$('input[type=checkbox][data-objective_description="' + objective_description + '"]').length) {

        var html = JST['templates/layouts/objectives_list_manual_item']({
          id: uniqueId,
          description: objective_description,
          model_name: 'knowledge_area_lesson_plan',
          submodel_name: 'lesson_plan'
        });

        $('#objectives-list').append(html);
        $('.list-group.checked-list-box .list-group-item:not(.initialized)').each(initializeListEvents);
      } else {
        var objective_input = $('input[type=checkbox][data-objective_description="' + objective_description + '"]');
        objective_input.closest('li').show();
        objective_input.prop('checked', true).trigger('change');
      }

      $('.knowledge_area_lesson_plan_lesson_plan_objectives_tags .select2-input').val("");
    }
    $(this).select2('val', '');
  });

  const addElement = (content) => {
    if (!$('li.list-group-item.active input[type=checkbox][data-content_description="' + content.description + '"]').length) {
      const newLine = JST['templates/layouts/contents_list_manual_item']({
        id: content.id,
        description: content.description,
        model_name: window['content_list_model_name'],
        submodel_name: window['content_list_submodel_name']
      });

      $('#contents-list').append(newLine);
      $('.list-group.checked-list-box .list-group-item:not(.initialized)').each(initializeListEvents);
    }
  };

  const fillContents = (data) => {
    if (data.knowledge_area_lesson_plans.length) {
      data.knowledge_area_lesson_plans.forEach(content => addElement(content));
    } else {
      copyFromTeachingPlanAlert.style.display = 'block';
    }
  }

  if (copyTeachingPlanLink) {
    copyTeachingPlanLink.addEventListener('click', event => {
      if (start_at.classList.contains('error') || end_at.classList.contains('error')){
        flashMessages.error('É necessário preenchimento das datas válidas para realizar a cópia.');
        return false;
      }

      event.preventDefault();
      copyFromTeachingPlanAlert.style.display = 'none';

      if (!knowledgeAreasInput.value) {
        flashMessages.error('É necessário preenchimento das áreas de conhecimento para realizar a cópia.');
        return false;
      }

      if (!startAtInput.value || !endAtInput.value) {
        flashMessages.error('É necessário preenchimento das datas para realizar a cópia.');
        return false;
      }
      const url = Routes.teaching_plan_contents_knowledge_area_lesson_plans_pt_br_path();
      const params = {
        classroom_id: $classroom.val(),
        knowledge_area_ids: knowledgeAreasInput.value,
        start_date: startAtInput.value,
        end_date: endAtInput.value
      }

      $.getJSON(url, params)
        .done(fillContents);
      return false;
    });
  }
  const addObjectives = (content) => {
    if (!$('li.list-group-item.active input[type=checkbox][data-objective_description="' + content.description + '"]').length) {
      const newLine = JST['templates/layouts/objectives_list_manual_item']({
        id: content.id,
        description: content.description,
        model_name: window['content_list_model_name'],
        submodel_name: window['content_list_submodel_name']
      });

      $('#objectives-list').append(newLine);
      $('.list-group.checked-list-box .list-group-item:not(.initialized)').each(initializeListEvents);
    }
  };

  const fillObjectives = (data) => {
    if (data.knowledge_area_lesson_plans.length) {
      data.knowledge_area_lesson_plans.forEach(content => addObjectives(content));
    } else {
      copyFromObjectivesTeachingPlanAlert.style.display = 'block';
    }
  }

  if (copyObjectivesTeachingPlanLink) {
    copyObjectivesTeachingPlanLink.addEventListener('click', event => {
      if (start_at.classList.contains('error') || end_at.classList.contains('error')){
        flashMessages.error('É necessário preenchimento das datas válidas para realizar a cópia.');
        return false;
      }

      event.preventDefault();
      copyFromObjectivesTeachingPlanAlert.style.display = 'none';

      if (!knowledgeAreasInput.value) {
        flashMessages.error('É necessário preenchimento das áreas de conhecimento para realizar a cópia.');
        return false;
      }

      if (!startAtInput.value || !endAtInput.value) {
        flashMessages.error('É necessário preenchimento das datas para realizar a cópia.');
        return false;
      }

      const url = Routes.teaching_plan_objectives_knowledge_area_lesson_plans_pt_br_path();
      const params = {
        classroom_id: $classroom.val(),
        knowledge_area_ids: knowledgeAreasInput.value,
        start_date: startAtInput.value,
        end_date: endAtInput.value
      }

      $.getJSON(url, params)
        .done(fillObjectives);

      return false;
    });
  }

  if ($('#action_name').val() == 'show') {
    $('.list-group.checked-list-box .list-group-item').each(function () {
      $(this).off('click');
    });
  }
});


$(function () {

  $('textarea[maxLength]').maxlength();

  createSummerNote("textarea[id^=knowledge_area_lesson_plan_lesson_plan_attributes_activities]", {
    toolbar: [
      ['font', ['bold', 'italic', 'underline', 'clear']],
    ]
  })

  createSummerNote("textarea[id^=knowledge_area_lesson_plan_lesson_plan_attributes_resources]", {
    toolbar: [
      ['font', ['bold', 'italic', 'underline', 'clear']],
    ]
  })

  createSummerNote("textarea[id^=knowledge_area_lesson_plan_lesson_plan_attributes_evaluation]", {
    toolbar: [
      ['font', ['bold', 'italic', 'underline', 'clear']],
    ]
  })

  createSummerNote("textarea[id^=knowledge_area_lesson_plan_lesson_plan_attributes_bibliography]", {
    toolbar: [
      ['font', ['bold', 'italic', 'underline', 'clear']],
    ]
  })
});
