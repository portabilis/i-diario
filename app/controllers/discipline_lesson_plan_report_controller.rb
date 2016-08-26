class DisciplineLessonPlanReportController < ApplicationController

  before_action :require_current_teacher

  DISCIPLINE_LESSON_PLAN_REPORT = "1"
  DISCIPLINE_CONTENT_RECORD = "2"

  def form
    @discipline_lesson_plan_report_form = DisciplineLessonPlanReportForm.new
    @discipline_lesson_plan_report_form.teacher_id = current_teacher_id
    fetch_collections
  end

  def report
    @discipline_lesson_plan_report_form = DisciplineLessonPlanReportForm.new(resource_params)
    @discipline_lesson_plan_report_form.teacher_id = current_teacher_id
    @discipline_lesson_plan_report_form.report_type = report_type

    if @discipline_lesson_plan_report_form.valid?

      if report_type == DISCIPLINE_LESSON_PLAN_REPORT
        lesson_plan_report = DisciplineLessonPlanReport.build(current_entity_configuration,
                                                                @discipline_lesson_plan_report_form.date_start,
                                                                @discipline_lesson_plan_report_form.date_end,
                                                                @discipline_lesson_plan_report_form.discipline_lesson_plan,
                                                                current_teacher)

        send_data(lesson_plan_report.render, filename: 'planos-de-ensino-por-disciplina.pdf', type: 'application/pdf', disposition: 'inline')
      elsif report_type == DISCIPLINE_CONTENT_RECORD
        content_record_report = DisciplineContentRecordReport.build(current_entity_configuration,
                                                                @discipline_lesson_plan_report_form.date_start,
                                                                @discipline_lesson_plan_report_form.date_end,
                                                                @discipline_lesson_plan_report_form.discipline_content_record,
                                                                current_teacher)

        send_data(content_record_report.render, filename: 'registro-de-conteudos-por-disciplinas.pdf', type: 'application/pdf', disposition: 'inline')
      end

    else
      @discipline_lesson_plan_report_form
      fetch_collections
      render :form
    end
  end

  private

  def fetch_collections
    @number_of_classes = current_school_calendar.number_of_classes
  end

  def resource_params
    params.require(:discipline_lesson_plan_report_form).permit(:unity_id,
                                                          :classroom_id,
                                                          :discipline_id,
                                                          :date_start,
                                                          :date_end)
  end

  def report_type
    params[:report_type]
  end
end
