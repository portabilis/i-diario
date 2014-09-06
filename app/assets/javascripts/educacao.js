//= require setup
//= require educacao-gmap
//= require_self

$(function () {
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
});
