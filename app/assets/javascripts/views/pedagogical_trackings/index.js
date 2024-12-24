var frequency_chart_ctx = document.getElementById('frequency_chart').getContext('2d');
var content_record_chart_ctx = document.getElementById('content_record_chart').getContext('2d');

var done_frequencies_percentage = $('#done_frequencies_percentage').val();
var done_content_records_percentage = $('#done_content_records_percentage').val();
var unknown_teachers = $('#unknown_teachers').val();

function textToCenter() {
  Chart.pluginService.register({
    beforeDraw: function(chart) {
      if (chart.config.options.elements.center) {
        // Get ctx from string
        var ctx = chart.chart.ctx;

        // Get options from the center object in options
        var centerConfig = chart.config.options.elements.center;
        var fontStyle = centerConfig.fontStyle || 'Arial';
        var txt = centerConfig.text;
        var color = centerConfig.color || '#000';
        var maxFontSize = centerConfig.maxFontSize || 75;
        var sidePadding = centerConfig.sidePadding || 20;
        var sidePaddingCalculated = (sidePadding / 100) * (chart.innerRadius * 2)
        // Start with a base font of 30px
        ctx.font = "30px " + fontStyle;

        // Get the width of the string and also the width of the element minus 10 to give it 5px side padding
        var stringWidth = ctx.measureText(txt).width;
        var elementWidth = (chart.innerRadius * 2) - sidePaddingCalculated;

        // Find out how much the font can grow in width.
        var widthRatio = elementWidth / stringWidth;
        var newFontSize = Math.floor(30 * widthRatio);
        var elementHeight = (chart.innerRadius * 2);

        // Pick a new font size so it will not be larger than the height of label.
        var fontSizeToUse = Math.min(newFontSize, elementHeight, maxFontSize);
        var minFontSize = centerConfig.minFontSize;
        var lineHeight = centerConfig.lineHeight || 25;
        var wrapText = false;

        if (minFontSize === undefined) {
          minFontSize = 20;
        }

        if (minFontSize && fontSizeToUse < minFontSize) {
          fontSizeToUse = minFontSize;
          wrapText = true;
        }

        // Set font settings to draw it correctly.
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        var centerX = ((chart.chartArea.left + chart.chartArea.right) / 2);
        var centerY = ((chart.chartArea.top + chart.chartArea.bottom) / 2);
        ctx.font = fontSizeToUse + "px " + fontStyle;
        ctx.fillStyle = color;

        if (!wrapText) {
          ctx.fillText(txt, centerX, centerY);
          return;
        }

        var words = txt.split(' ');
        var line = '';
        var lines = [];

        // Break words up into multiple lines if necessary
        for (var n = 0; n < words.length; n++) {
          var testLine = line + words[n] + ' ';
          var metrics = ctx.measureText(testLine);
          var testWidth = metrics.width;
          if (testWidth > elementWidth && n > 0) {
            lines.push(line);
            line = words[n] + ' ';
          } else {
            line = testLine;
          }
        }

        // Move the center up depending on line height and number of lines
        centerY -= (lines.length / 2) * lineHeight;

        for (var n = 0; n < lines.length; n++) {
          ctx.fillText(lines[n], centerX, centerY);
          centerY += lineHeight;
        }
        //Draw text in center
        ctx.fillText(line, centerX, centerY);
      }
    }
  });
}

function clear_empty(element) {
  if (element.val === "empty") {
    $(element.target).select2("val", "");
  }
}

function build_pie_chart(ctx, done_percentage, unknown_teachers = null){
  var labels = ['% Não Lançados', '% Lançados']
  var data = [(100 - done_percentage).toFixed(2), done_percentage]
  var backgroundColor = ['rgba(191, 74, 74, 1)', 'rgba(133, 191, 74, 1)']
  var borderColor = ['rgba(191, 74, 74, 1)', 'rgba(133, 191, 74, 1)']

  if (unknown_teachers) {
    labels.push('% Período não mapeado');
    data = [(100 - (parseFloat(done_percentage) + parseFloat(unknown_teachers))).toFixed(2), done_percentage, unknown_teachers]
    backgroundColor.push('rgba(229, 201, 98, 1)');
    borderColor.push('rgba(229, 201, 98, 1)');
  }

  textToCenter()

  new Chart(ctx, {
      type: 'doughnut',
      data: {
          labels: labels,
          datasets: [{
              data: data,
              backgroundColor: backgroundColor,
              borderColor: borderColor,
              borderWidth: 0.5
          }]
      },
      options: {
        cutoutPercentage: 70,
        elements: {
          center: {
            text: 'Você selecionou um total de ' + $('#school_days').val() + ' dias letivos',
            color: '#888888', // Default is #000000
            fontStyle: 'Arial', // Default is Arial
            sidePadding: 20, // Default is 20 (as a percentage)
            minFontSize: 15, // Default is 20 (in px), set to false and text will not wrap.
            lineHeight: 15 // Default is 25 (in px), used for when text wraps
          }
        }
      }
  });
}

$(document).ready( function() {
  let beta_title = 'Este recurso ainda está em processo de desenvolvimento e pode apresentar problemas'
  let img_src = $('#image-beta').attr('src');
  $('.fa-pie-chart').closest('h2').after(`<img src="${img_src}" class="beta-badge" style="margin-bottom: 9px; margin-left: 5px" title="${beta_title}">`);
})

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
var step_start_date = $('#step_start_date').val();
var step_end_date = $('#step_end_date').val();

if (unity_id) {
  $('#search_unity_id').val(unity_id);
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
