var frequency_chart_ctx = document.getElementById('frequency_chart').getContext('2d');
var content_record_chart_ctx = document.getElementById('content_record_chart').getContext('2d');

var done_frequencies_percentage = $('#done_frequencies_percentage').val();
var done_content_records_percentage = $('#done_content_records_percentage').val();

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
  $('form.filter_tracking_search_form').trigger("submit");
});
$('#search_start_date').on('change', function(e){
  $('form.filter_tracking_search_form').trigger("submit");
});
$('#search_end_date').on('change', function(e){
  $('form.filter_tracking_search_form').trigger("submit");
});

var url_string = window.location.href;
var url = new URL(url_string);
var unity_id = url.searchParams.get("search[unity_id]");
var start_date = url.searchParams.get("search[start_date]");
var end_date = url.searchParams.get("search[end_date]");

if (unity_id && unity_id != 'empty') {
  $('#search_unity_id').val(unity_id);

  $('#search_partial_unity_id').val(unity_id);
  $('#search_partial_unity_id').attr('readonly','readonly');
  $('#search_frequency_operator').attr('readonly','readonly');
  $('#search_content_record_operator').attr('readonly','readonly');
}

if (start_date) {
  $('#search_start_date').val(start_date);
}

if (end_date) {
  $('#search_end_date').val(end_date);
}
