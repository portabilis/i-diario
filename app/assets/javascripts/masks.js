$(function () {
  $('input[data-mask]').on('focus', function () {
    var input = $(this);

    input.inputmask(input.data('mask'));
  });

  $('input.tel').on('focusout', function () {
    var tel = $(this).val().replace(/[^\d+]/g, '');

    if (tel.length == 10) {
      $(this).val(tel.replace(/(\d{2})(\d{4})(\d{4})/, "($1) $2-$3"));
    }
  });

  $('input.zip_code').on('blur', function () {
    var zipCode = $(this).val().replace(/[^\d]/g, ''),
        $number = $('input[id$=_number]'),
        $neighborhood = $('input[id$=_neighborhood]'),
        $complement = $('input[id$=_complement]'),
        $street = $('input[id$=_street]'),
        $city = $('input[id$=_city]'),
        $state = $('select[id$=_state]'),
        $country = $('input[id$=_country]'),
        $latitude = $('input[id$=_latitude]'),
        $longitude = $('input[id$=_longitude]'),
        $destroy = $('input[id$=_destroy]');

    $latitude.val('');
    $longitude.val('');
    $street.val('');
    $number.val('');
    $complement.val('');
    $neighborhood.val('');
    $city.val('');
    $state.val('');
    $country.val('');

    $.getJSON('http://cep.correiocontrol.com.br/'+ zipCode +'.json').always(function (address) {
      if (typeof(address['logradouro']) != 'undefined') {
        if (typeof(address['uf']) == 'undefined') {
          address['uf'] = "";
        }

        $street.val(address['logradouro']);
        $neighborhood.val(address['bairro']);
        $city.val(address['localidade']);
        $state.val(address['uf'].toLocaleLowerCase());
        $country.val('Brasil');

        $number.focus();

        $destroy.val(false);

        var fullAddress = address['logradouro'] + ", " + $number.val() + ", ";
        fullAddress = fullAddress + ", " + address['bairro'] + ', ' + address['localidade'] + ', ' + address['uf'];

        $('#map-address').trigger('gmap-address:set', fullAddress);
      } else {
        $destroy.val(true);
      }
    });
  });
});
