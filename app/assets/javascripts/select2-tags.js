$(function() {
  'use strict';
  _.each($('.select2-tags'), function(element) {
    $(element).select2({
      tags: true,
      tokenSeparators: [','],
      createSearchChoice: function (term) {
          return {
              id: $.trim(term),
              text: $.trim(term) + ' (Novo conteúdo)'
          };
      },
      data: $(element).data('elements')
    });
  });
});