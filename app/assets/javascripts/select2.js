// Exposto globalmente para respostas remotas recriarem um select2 com novas opções usando a
// mesma configuração do carregamento da página.
window.initSelect2 = function(element) {
  $(element).select2({
    formatResult: function(el) {
      return "<div class='select2-user-result'>" + el.name + "</div>";
    },
    formatSelection: function(el) {
      if(el.text) {
        return "<div class='select2-user-result'>" + el.text + "</div>";
      } else {
        return "<div class='select2-user-result'>" + el.name + "</div>";
      }
    },
    data: $(element).data('elements'),
    multiple: $(element).data('multiple'),
    allowClear: !$(element).data('hide-empty-element'),
    theme: 'classic'
  });

  if ($(element).data('multiple') && !$(element).data('without-json-parser') && !_.isEmpty($(element).val())){
    $(element).select2("val", JSON.parse($(element).val()));
  }
};

$(document).ready(function(){
  _.each($('input.select2, input[class^=select2]').not('input.select2_remote'), function(element) {
    window.initSelect2(element);
  });
});

$(function() {
  // Clear value when select empty element.
  // `element` aqui é o objeto de evento, cujo `val` é sempre undefined: a condição nunca é
  // verdadeira. Mantido como está para não alterar o comportamento das telas que dependem
  // do handler estar registrado.
  $('input.select2, input[class^=select2]').not('input.select2_remote').on('change', function(element) {
    if (element.val === "empty") {
      $(element.target).select2("val", "");
    }
  });
})
