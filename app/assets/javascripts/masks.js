$(function () {
  var applyMasks = function () {
    $('input[data-mask]').on('focus', function () {
      var input = $(this);

      input.inputmask(input.attr('data-mask'));
    });
  };

  $('body').on('cocoon:after-insert', function(e) {
    applyMasks();
  });

  applyMasks();

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

    $.ajax({
      url: 'https://viacep.com.br/ws/'+ zipCode +'/json',
      dataType: 'json',
      timeout: 5000
    }).fail(function() {
      $('#cep-timout-flash-message').removeClass('hidden')
    }).done(function (address) {
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

      $('#cep-timout-flash-message').addClass('hidden')
    });
  });
});
