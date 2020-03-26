var frequency_chart_ctx = document.getElementById('frequency_chart').getContext('2d');
var content_record_chart_ctx = document.getElementById('content_record_chart').getContext('2d');

var done_frequencies_percentage = $('#done_frequencies_percentage').val();
var done_content_records_percentage = $('#done_content_records_percentage').val();

function clear_empty(element) {
  if (element.val === "empty") {
    $(element.target).select2("val", "");
  }
}

function build_pie_chart(ctx, done_percentage){
  new Chart(ctx, {
      type: 'pie',
      data: {
          labels: ['% Não Lançados', '% Lançados'],
          datasets: [{
              data: [100 - done_percentage, done_percentage],
              backgroundColor: [
                  'rgba(255, 0, 0, 0.8)',
                  'rgba(0, 255, 0, 0.8)'
              ],
              borderColor: [
                'rgba(255, 255, 255, 1)',
                'rgba(255, 255, 255, 1)'
              ],
              borderWidth: 1
          }]
      },
      options: {
      }
  });
}

build_pie_chart(frequency_chart_ctx, done_frequencies_percentage);
build_pie_chart(content_record_chart_ctx, done_content_records_percentage);

$('#search_unity_id').on('change', function(e){
  clear_empty(e);
  $('form.filter_tracking_search_form').trigger("submit");
});
$('#search_start_date').on('change', function(e){
  clear_empty(e);
  $('form.filter_tracking_search_form').trigger("submit");
});
$('#search_end_date').on('change', function(e){
  clear_empty(e);
  $('form.filter_tracking_search_form').trigger("submit");
});

var url_string = window.location.href;
var url = new URL(url_string);
var unity_id = url.searchParams.get("search[unity_id]");
var start_date = url.searchParams.get("search[start_date]");
var end_date = url.searchParams.get("search[end_date]");

if (unity_id && unity_id != 'empty') {
  $('#search_unity_id').val(unity_id);
}

if (start_date) {
  $('#search_start_date').val(start_date);
  $('#start_date').val(start_date);
}

if (end_date) {
  $('#search_end_date').val(end_date);
  $('#end_date').val(end_date);
}

if (_.isEmpty($('#filter_frequency_operator').val())){
  $('#filter_frequency_percentage').attr('readonly', true).val('');
}
if (_.isEmpty($('#filter_content_record_operator').val())){
  $('#filter_content_record_percentage').attr('readonly', true).val('');
}

$('form.percent_filterable_search_form input, form.percent_filterable_search_form input.select2').on('change',
  function (e){
    clear_empty(e);

    if (this.id == 'filter_frequency_operator') {
      if (_.isEmpty($('#filter_frequency_operator').val())){
        $('#filter_frequency_percentage').attr('readonly', true).val('');
      } else {
        $('#filter_frequency_percentage').removeAttr('readonly');
        $('#filter_frequency_percentage').focus();
      }
    }

    if (this.id == 'filter_content_record_operator') {
      if (_.isEmpty($('#filter_content_record_operator').val())){
        $('#filter_content_record_percentage').attr('readonly', true).val('');
      } else {
        $('#filter_content_record_percentage').removeAttr('readonly');
        $('#filter_content_record_percentage').focus();
      }
    }

    if ((this.id == 'filter_frequency_percentage' && _.isEmpty($('#filter_frequency_percentage').val())) ||
        (this.id == 'filter_content_record_percentage' &&_.isEmpty($('#filter_content_record_percentage').val()))) {
      return false;
    }

    if ((this.id == 'filter_frequency_operator' && _.isEmpty($('#filter_frequency_percentage').val()) && !($('#filter_frequency_percentage').attr('readonly'))) ||
        (this.id == 'filter_content_record_operator' && _.isEmpty($('#filter_content_record_percentage').val()) && !($('#filter_frequency_percentage').attr('readonly'))))
    {
      return false;
    }

    $.get(
      $('form.percent_filterable_search_form').attr('action'),
      $('form.percent_filterable_search_form').serialize(),
      null,
      'script'
    );

    return false;
  }
);
