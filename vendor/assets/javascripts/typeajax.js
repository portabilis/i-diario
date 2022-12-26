(function ($, _) {
  var Typeajax = function (element) {
    this.$element = $(element);
    this.$hidden = this.$element.prev('input[type=hidden]');

    // Keep this context because these functions are attached to other contexts.
    _.bindAll(this, 'fetch', 'source', 'updater', 'change');

    // Do not hit the server on every type, postpone the fetch until after 300
    // milliseconds have elapsed since the last type.
    this.fetch = _.debounce(this.fetch, 300);

    this.$element.typeahead({
      source: this.source,
      items: Infinity,
      matcher: _.identity,
      sorter: _.identity,
      highlighter: this.highlighter,
      updater: this.updater
    });

    this.$element.on("change", this.change);
  };

  Typeajax.prototype = {
    constructor: Typeajax,

    source: function (query, process) {
      if (this.jqXHR) {
        this.jqXHR.abort();
      }

      this.fetch(query, process);
    },

    fetch: function (query, process) {
      var $element = this.$element,
          url = $element.data("typeahead-url");

      // Handle a condition where the user clear the input before this function
      // is triggered due to the debounce. It happens because the source is not
      // triggered when the input is cleared and regardless of that, there is
      // no way to abort the last debounce call.
      if ($element.val() !== query) {
        return;
      }

      // Do not accept an empty URL since the jQuery will hit the current
      // location and it will probably be a mistake of the programmer.
      if (!url) {
        throw new Error("Missing data-typeahead-url for input #" + $element.attr("id"));
      }

      process([JSON.stringify({ value: '<i class="icon-spinner icon-spin"></i> Procurando', ignoreClick: true })]);

      this.jqXHR = $.getJSON(url, { q: query });

      this.jqXHR.done(function (data) {
        // Handle a condition where the user clear the input before the last
        // request finishes. It happens because the source is not triggered
        // when the input is cleared leading the request to finish instead of
        // being aborted.
        if ($element.val() !== query) {
          return;
        }

        if (data.length) {
          data = _.map(data, function (item) {
            return JSON.stringify(item);
          });

          process(data);
        } else {
          process([JSON.stringify({ value: '<i class="icon-thumbs-down"></i> Desculpe, mas nada foi encontrado com o termo "' + query + '"', ignoreClick: true })]);
        }
      });

      this.jqXHR.fail(function (jqXHR, textStatus, errorThrown) {
        if (textStatus === 'abort') {
          return;
        }

        process([JSON.stringify({ value: '<i class="icon-warning-sign"></i> Desculpe, mas ocorreu um erro: (' + jqXHR.status + ')', ignoreClick: true })]);
      });
    },

    highlighter: function (item) {
      item = JSON.parse(item);

      // Do not highlight loading, not found and error states.
      if (!item.id) {
        return item.value;
      }

      var query = this.query.replace(/[\-\[\]{}()*+?.,\\\^$|#\s]/g, '\\$&');

      return item.value.replace(new RegExp('(' + query + ')', 'ig'), function ($1, match) {
        return '<strong>' + match + '</strong>'
      });
    },

    updater: function (item) {
      item = JSON.parse(item);

      this.$hidden.val(item.id);
      this.$hidden.trigger('typeajax:after-update', item);

      return item.value;
    },

    change: function () {
      if (this.$element.val()) {
        return;
      }

      this.$hidden.val('');
    }
  };

  $.fn.typeajax = function (option) {
    return this.each(function () {
      var $this = $(this),
          data = $this.data('typeajax');

      if (!data) $this.data('typeajax', (data = new Typeajax(this)))
      if (typeof option == 'string') data[option]()
    });
  };
})(window.jQuery, window._);
