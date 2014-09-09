$(function () {
  $('input[data-mask]').on('focus', function () {
    var input = $(this);

    input.inputmask(input.data('mask'));
  });

  $('input.zip_code').on('blur', function () {
    var zipCode = $(this).val().replace(/[^\d]/g, ''),
        $number = $('input[id$=_number]'),
        $neighborhood = $('input[id$=_neighborhood]'),
        $street = $('input[id$=_street]'),
        $city = $('input[id$=_city]'),
        $state = $('select[id$=_state]'),
        $country = $('input[id$=_country]'),
        $latitude = $('input[id$=_latitude]'),
        $longitude = $('input[id$=_longitude]');

    $latitude.val('');
    $longitude.val('');

    $.getJSON('http://cep.correiocontrol.com.br/'+ zipCode +'.json').always(function (address) {
      if (typeof(address['uf']) == 'undefined') {
        address['uf'] = "";
      }

      $street.val(address['logradouro']);
      $neighborhood.val(address['bairro']);
      $city.val(address['localidade']);
      $state.val(address['uf'].toLocaleLowerCase());
      $country.val('Brasil');

      $number.focus();

      var fullAddress = address['logradouro'] + ", " + $number.val() + ", ";
      fullAddress = fullAddress + ", " + address['bairro'] + ', ' + address['localidade'] + ', ' + address['uf'];

      $('#map-address').trigger('gmap-address:set', fullAddress);
    });
  });
});
