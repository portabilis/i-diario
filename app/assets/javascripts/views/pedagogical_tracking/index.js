var frequency_chart_ctx = document.getElementById('frequency_chart').getContext('2d');
var content_record_chart_ctx = document.getElementById('content_record_chart').getContext('2d');

var done_frequencies_percentage = $('#done_frequencies_percentage').val();
var done_content_records_percentage = $('#done_content_records_percentage').val();
var unknown_teachers = $('#unknown_teachers').val();

function clear_empty(element) {
  if (element.val === "empty") {
    $(element.target).select2("val", "");
  }
}

function build_pie_chart(ctx, done_percentage, unknown_teachers = null){
  var labels = ['% Não Lançados', '% Lançados']
  var data = [(100 - done_percentage).toFixed(2), done_percentage]
  var backgroundColor = ['rgba(255, 0, 0, 0.8)', 'rgba(0, 255, 0, 0.8)']
  var borderColor = ['rgba(255, 0, 0, 1)', 'rgba(0, 255, 0, 1)']

  if (unknown_teachers) {
    labels.push('% Lançamentos desconhecidos');
    data = [(100 - (parseFloat(done_percentage) + parseFloat(unknown_teachers))).toFixed(2), done_percentage, unknown_teachers]
    backgroundColor.push('rgba(0, 0, 255, 0.8)');
    borderColor.push('rgba(0, 0, 255, 1)');
  }

  new Chart(ctx, {
      type: 'pie',
      data: {
          labels: labels,
          datasets: [{
              data: data,
              backgroundColor: backgroundColor,
              borderColor: borderColor,
              borderWidth: 1
          }]
      },
      options: {
      }
  });
}

build_pie_chart(frequency_chart_ctx, done_frequencies_percentage, unknown_teachers);
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

var unity_id = $('#unity_id').val();
var start_date = $('#start_date').val();
var end_date = $('#end_date').val();
var step_start_date = $('#step_start_date').val();
var step_end_date = $('#step_end_date').val();

if (unity_id) {
  $('#search_unity_id').val(unity_id);
}

if (start_date) {
  $('#search_start_date').val(start_date);
} else {
  $('#search_start_date').attr('placeholder', step_start_date)
}

if (end_date) {
  $('#search_end_date').val(end_date);
} else {
  $('#search_end_date').attr('placeholder', step_end_date)
}

if (_.isEmpty($('#filter_frequency_operator').val())){
  $('#filter_frequency_percentage').attr('readonly', true).val('');
}
if (_.isEmpty($('#filter_content_record_operator').val())){
  $('#filter_content_record_percentage').attr('readonly', true).val('');
}

var typingTimer;

$('#filter_frequency_percentage, \
  #filter_content_record_percentage, \
  #search_teacher_frequency_percentage, \
  #search_teacher_content_record_percentage').keyup(function() {
  clearTimeout(typingTimer);
  var self = $(this);
  typingTimer = setTimeout(function(){
    self.trigger('change');
  }, 1200);
});

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

    if ((this.id == 'filter_frequency_percentage' &&
         _.isEmpty($('#filter_frequency_percentage').val())) ||
        (this.id == 'filter_content_record_percentage' &&
         _.isEmpty($('#filter_content_record_percentage').val()))) {
      return false;
    }

    if ((this.id == 'filter_frequency_operator' &&
         _.isEmpty($('#filter_frequency_percentage').val()) &&
         !($('#filter_frequency_percentage').attr('readonly'))) ||
        (this.id == 'filter_content_record_operator' &&
         _.isEmpty($('#filter_content_record_percentage').val()) &&
         !($('#filter_frequency_percentage').attr('readonly')))) {
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
