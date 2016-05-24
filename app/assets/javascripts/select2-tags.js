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
      data: $(element).data('elements'),
      formatLoadMore   : 'Carregando mais...',
      query            : function (q) {
      // pageSize is number of results to show in dropdown
          var pageSize,
              results;
              pageSize = 20;
              results  = _.filter(this.data, function (e) {
                  return (q.term === "" || e.text.toUpperCase().indexOf(q.term.toUpperCase()) >= 0);
           });
          q.callback({
              results: results.slice((q.page - 1) * pageSize, q.page * pageSize),
              // retrieve more when user hits bottom
              more   : results.length >= q.page * pageSize
          });
      }

    });
  });
});