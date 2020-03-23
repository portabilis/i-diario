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
