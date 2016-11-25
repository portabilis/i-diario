$(function () {
  'use strict';

  // Regular expression for dd/mm/yyyy date including validation for leap year and more
  var dateRegex = '^(?:(?:31(\\/)(?:0?[13578]|1[02]))\\1|(?:(?:29|30)(\\/)(?:0?[1,3-9]|1[0-2])\\2))(?:(?:1[6-9]|[2-9]\\d)?\\d{2})$|^(?:29(\\/)0?2\\3(?:(?:(?:1[6-9]|[2-9]\\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00))))$|^(?:0?[1-9]|1\\d|2[0-8])(\\/)(?:(?:0?[1-9])|(?:1[0-2]))\\4(?:(?:1[6-9]|[2-9]\\d)?\\d{2})$';
  var flashMessages = new FlashMessages();
  var $classroom = $('#knowledge_area_content_record_content_record_attributes_classroom_id');
  var $knowledgeArea = $('#knowledge_area_content_record_knowledge_area_ids');
  var $recordDate = $('#knowledge_area_content_record_content_record_attributes_record_date');

  $classroom.on('change', function(){
    var classroom_id = $classroom.select2('val');

    /*$knowledgeArea.select2('val', '');
    $knowledgeArea.select2({ data: [] });

    if (!_.isEmpty(classroom_id)) {
      fetchKnowledgeAreas(classroom_id);
    }*/
    loadContents();
  });


  var handleFetchContentsSuccess = function(data){
    if (!_.isEmpty(data.contents)) {
      _.each(data.contents, function(content) {
        if(!$('input[type=checkbox][data-content_description="'+content.description+'"]').length){
          var html = JST['templates/knowledge_area_content_records/contents_list_item'](content);
          $('#contents-list').append(html);
        }
      });
      $('.list-group.checked-list-box .list-group-item:not(.initialized)').each(initializeListEvents);
    }
  }

  var handleFetchContentsError = function(){
    flashMessages.error('Ocorreu um erro ao buscar os conteúdos de acordo com filtros informados.');
  }

  var fetchContents = function(classroom_id, knowledge_area_ids, date){
    var params = {
      classroom_id: classroom_id,
      knowledge_area_ids: knowledge_area_ids,
      date: date,
      fetch_for_knowledge_area_records: true,
      format: "json"
    }
    $.ajax({
      url: Routes.contents_pt_br_path(params),
      success: handleFetchContentsSuccess,
      error: handleFetchContentsError
    });

  }

  var loadContents = function(){
    var classroom_id = $classroom.select2('val');
    var knowledge_area_ids = $knowledgeArea.select2('val');
    var date = $recordDate.val();
    $('#contents-list .list-group-item:not(.manual)').remove();

    if (!_.isEmpty(classroom_id) &&
        !_.isEmpty(knowledge_area_ids) &&
        !_.isEmpty(date.match(dateRegex))) {
      fetchContents(classroom_id, knowledge_area_ids, date);
    }
  }

  $knowledgeArea.on('change', function(){
    loadContents();
  });

  $recordDate.on('change', function(){
    loadContents();
  });

  function fetchKnowledgeAreas(classroom_id) {
    $.ajax({
      url: Routes.knowledge_areas_pt_br_path({ classroom_id: classroom_id, format: 'json' }),
      success: handlefetchKnowledgeAreasSuccess,
      error: handlefetchKnowledgeAreasError
    });
  };

  function handlefetchKnowledgeAreasSuccess(knowledge_areas) {
    var selectedKnowledgeAreas = _.map(knowledge_areas, function(knowledge_area) {
      return { id: knowledge_area['id'], text: knowledge_area['description'] };
    });

    $knowledgeArea.select2({ data: selectedKnowledgeAreas });
  };

  function handlefetchKnowledgeAreasError() {
    flashMessages.error('Ocorreu um erro ao buscar as áreas de conhecimento da turma selecionada.');
  };

  var initializeListEvents = function () {

    // Settings
    var $widget = $(this),
        $checkbox = $(this).find('input[type=checkbox]').first(),
        color = "info",
        style = "list-group-item-",
        settings = {
            on: {
                icon: 'fa fa-check'
            },
            off: {
                icon: 'margin-left-17px'
            }
        };

    $widget.css('cursor', 'pointer')

    // Event Handlers
    $widget.on('click', function () {
      $checkbox.prop('checked', !$checkbox.is(':checked'));
      $checkbox.triggerHandler('change');
      updateDisplay();
    });
    $checkbox.on('change', function () {
        updateDisplay();
    });


    // Actions
    function updateDisplay() {
        var isChecked = $checkbox.is(':checked');

        // Set the button's state
        $widget.data('state', (isChecked) ? "on" : "off");

        // Set the button's icon
        $widget.find('.state-icon')
            .removeClass()
            .addClass('state-icon ' + settings[$widget.data('state')].icon);

        // Update the button's color
        if (isChecked) {
            $widget.addClass(style + color + ' active');
        } else {
            $widget.removeClass(style + color + ' active');
        }
    }

    // Initialization
    function init() {

        if ($widget.data('checked') == true) {
            $checkbox.prop('checked', !$checkbox.is(':checked'));
        }

        updateDisplay();

        $widget.addClass('initialized');

        // Inject the icon if applicable
        if ($widget.find('.state-icon').length == 0) {
            $widget.prepend('<span class="state-icon ' + settings[$widget.data('state')].icon + '"></span>');
        }
    }
    init();
  }

  $('.list-group.checked-list-box .list-group-item').each(initializeListEvents);

  $('#knowledge_area_content_record_content_record_attributes_contents_tags').on('change', function(e){
    if(e.val.length){
      var content_description = e.val.join(", ");
      if(content_description.trim().length &&
          !$('input[type=checkbox][data-content_description="'+content_description+'"]').length){

        var html = JST['templates/knowledge_area_content_records/contents_list_manual_item']({
          description: content_description
        });
        $('#contents-list').append(html);
        $('.list-group.checked-list-box .list-group-item:not(.initialized)').each(initializeListEvents);
      }else{
        $('input[type=checkbox][data-content_description="'+content_description+'"]').prop('checked', true)
                                                                                    .trigger('change');
      }
    }
    $(this).select2('val', '');
  });
});
