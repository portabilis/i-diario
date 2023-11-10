function initializeListEvents() {
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

function hideContent(content) {
  content.find("input[type=checkbox]").prop('checked', true);
  content.remove();
}

function editContent(id) {
  var content = $('#' + id);
  var inputAddContent = $('.contents-select2-container .select2-input');
  inputAddContent.val(content.find("input[type=checkbox]").data('content_description'));
  inputAddContent.trigger('click');
  inputAddContent.focus();
  hideContent(content);
}

function removeContent(id) {
  var content = $('#' + id);
  hideContent(content);
}

function editObjective(id) {
  var objective = $('#' + id);
  var inputAddObjective = $('.objectives-select2-container .select2-input');
  inputAddObjective.val(objective.find("input[type=checkbox]").data('objective_description'));
  inputAddObjective.trigger('click');
  inputAddObjective.focus();
  hideContent(objective);
}

function removeObjective(id) {
  var objective = $('#' + id);
  hideContent(objective);
}

$(function () {
  $('.list-group.checked-list-box .list-group-item').each(initializeListEvents);

  window.Select2.class.multi.prototype.clearSearch=function(){
      var placeholder = this.getPlaceholder(),
          maxWidth = this.getMaxSearchWidth();

      if (placeholder !== undefined  && this.getVal().length === 0 &&  this.search.val()=="") {
        this.search.val(placeholder).addClass("select2-default");
        this.search.width(maxWidth > 0 ? maxWidth : this.container.css("width"));
      }
  }
});
