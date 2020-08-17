// Grabbed from https://stackoverflow.com/a/6178341
function isValidDate(dateString) {
  // First check for the pattern
  if (!/^\d{1,2}\/\d{1,2}\/\d{4}$/.test(dateString))
    return false;

  // Parse the date parts to integers
  let parts = dateString.split("/");
  let day = parseInt(parts[0], 10);
  let month = parseInt(parts[1], 10);
  let year = parseInt(parts[2], 10);

  // Check the ranges of month and year
  if (year < 1000 || year > 3000 || month == 0 || month > 12)
    return false;

  var monthLength = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  // Adjust for leap years
  if (year % 400 == 0 || (year % 100 != 0 && year % 4 == 0))
    monthLength[1] = 29;

  // Check the range of the day
  return day > 0 && day <= monthLength[month - 1];
};

$(document).ready(function() {
  $('.datepicker').on('change', function() {
    let value = $(this).val();
    let error_msg = "deve ser uma data válida";
    let error = '<span class="help-inline">' + error_msg + '</span>';

    if (value) {
      let wrapper = $(this).closest('div.control-group');

      if (!isValidDate(value)) {
        if (wrapper) {
          let found_error = wrapper.find('.help-inline');

          wrapper.addClass("error");

          if (found_error.length == 0) {
            wrapper.append(error);
            return false
          }

          found_error.html(error_msg);
        }

        return false
      } else {
        if (wrapper) {
          wrapper.removeClass("error")
          wrapper.find('.help-inline').remove();
        }
      }

      $(this).trigger('valid-date');
    }
  });
});
