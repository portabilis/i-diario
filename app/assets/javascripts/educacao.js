//= require setup
//= require educacao-gmap
//= require_self

$(function () {
  $('#map-address').on('gmap-address:update', function (e, position) {
    var $latitude = $('input[id$=_latitude]'),
        $longitude = $('input[id$=_longitude]');

    $latitude.val(position.lat());
    $longitude.val(position.lng());
  });

  $('#map-address').gmapAddress();
});
