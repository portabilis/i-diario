$(function(){
  var ctx = document.getElementById("teacher-work-done-chart");
  var flashMessages = new FlashMessages();

  $schoolCalendarStepElement = $('#school_calendar_step');
  $schoolCalendarStepElement.on('change', mountWorkDoneChart);

  function mountWorkDoneChart(){
    var teacherId = $('#current_teacher_id').val();
    var schoolCalendarStepId = $('#school_calendar_step').val();
    $.ajax({
      url: Routes.dashboard_teacher_work_done_chart_index_pt_br_path(
        { 
          format: 'json', 
          teacher_id: teacherId, 
          school_calendar_step_id: schoolCalendarStepId
        }
      ),
      success: handleFetchTeacherWorkDoneChartSuccess,
      error: handleFetchTeacherWorkDoneChartError
    });
  }

  function handleFetchTeacherWorkDoneChartSuccess(teacher_notes) {
    var data = {
    labels: [
      "Notas lançadas",
      "Notas não lançadas"
    ],
    datasets: [
        {
          data: [teacher_notes.not_nil_notes, teacher_notes.nil_notes],
          backgroundColor: [
              "#36A2EB",
              "#FF6384"
              
          ],
          hoverBackgroundColor: [
              "#36A2EB",
              "#FF6384"
          ]
        }
      ]
    };
    var avaliationsNotDonePieChart = new Chart(ctx,{
      type: 'pie',
      data: data,
      options: {
        animation:{
            animateScale:true
        }
      }
    });
  };

  function handleFetchTeacherWorkDoneChartError() {
    flashMessages.error('Ocorreu um erro ao buscar os dados para preencher o gráfico de trabalho realizado.');
  };

  mountWorkDoneChart();
});
