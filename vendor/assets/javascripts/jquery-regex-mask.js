(function ($){
  $.fn.regexMask = function (mask) {
      if (!mask) {
          throw 'mandatory mask argument missing';
      } else if (mask == 'float-ptbr') {
          mask = /^((\d{1,3}(\.\d{3})*(((\.\d{0,2}))|((\,\d*)?)))|(\d+(\,\d*)?))$/;
      } else if (mask == 'float-enus') {
          mask = /^((\d{1,3}(\,\d{3})*(((\,\d{0,2}))|((\.\d*)?)))|(\d+(\.\d*)?))$/;
      } else if (mask == 'integer') {
          mask = /^\d+$/;
      } else {
          try {
              mask.test("");
          } catch(e) {
              throw 'mask regex need to support test method';
          }
      }
      $(this).keypress(function (event) {
          if (!event.charCode) return true;
          var part1 = this.value.substring(0,this.selectionStart);
          var part2 = this.value.substring(this.selectionEnd,this.value.length);
          if (!mask.test(part1 + String.fromCharCode(event.charCode) + part2))
              return false;
      });
  };
})(jQuery);