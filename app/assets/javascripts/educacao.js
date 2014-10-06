//= require setup
//= require educacao-gmap
//= require_self

$(function () {
  $.ajaxSetup({
    beforeSend: function () {
      $('body').append('<div id="page-loading"><i class="fa fa-cog fa-spin"></i></div>');
    },
    complete: function () {
      $('#page-loading').remove();
    }
  });

  $('nav ul').jarvis***REMOVED***({
    accordion : true,
    speed : 235,
    closedSign : '<em class="fa fa-plus-square-o"></em>',
    openedSign : '<em class="fa fa-minus-square-o"></em>'
  });

  $('#map-address').on('gmap-address:update', function (e, position) {
    var $latitude = $('input[id$=_latitude]'),
        $longitude = $('input[id$=_longitude]');

    $latitude.val(position.lat());
    $longitude.val(position.lng());
  });

  $('#map-address').gmapAddress();

  $('[data-toggle=popover]').popover({
    trigger: 'focus'
  });

  $('#widget-grid').jarvisWidgets({
    grid : 'article',
    widgets : '.jarviswidget',
    sortable: false,
    toggleButton: false,
    deleteButton: false,
    editButton : false,
    colorButton : false,
    fullscreenButton : true,
    fullscreenClass : 'fa fa-expand | fa fa-compress',
    fullscreenDiff : 3,
    onFullscreen : function() {
    }
  });
});
