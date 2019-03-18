class DisciplineLessonPlanReportController < ApplicationController
  DISCIPLINE_LESSON_PLAN_REPORT = "1"
  DISCIPLINE_CONTENT_RECORD = "2"

  before_action :require_current_teacher

  def form
    @discipline_lesson_plan_report_form = DisciplineLessonPlanReportForm.new
    @discipline_lesson_plan_report_form.teacher_id = current_teacher_id
    fetch_collections
  end

  def lesson_plan_report
    @discipline_lesson_plan_report_form = DisciplineLessonPlanReportForm.new(resource_params)
    @discipline_lesson_plan_report_form.teacher_id = current_teacher_id
    @discipline_lesson_plan_report_form.report_type = DISCIPLINE_LESSON_PLAN_REPORT

    if @discipline_lesson_plan_report_form.valid?
      lesson_plan_report = DisciplineLessonPlanReport.build(current_entity_configuration,
                                                            @discipline_lesson_plan_report_form.date_start,
                                                            @discipline_lesson_plan_report_form.date_end,
                                                            @discipline_lesson_plan_report_form.discipline_lesson_plan,
                                                            current_teacher)
      send_pdf(t("routes.lesson_plan_record"), lesson_plan_report.render)
    else
      @discipline_lesson_plan_report_form
      fetch_collections
      clear_invalid_dates
      render :form
    end
  end

  def content_record_report
    @discipline_lesson_plan_report_form = DisciplineLessonPlanReportForm.new(resource_params)
    @discipline_lesson_plan_report_form.teacher_id = current_teacher_id
    @discipline_lesson_plan_report_form.report_type = DISCIPLINE_CONTENT_RECORD

    if @discipline_lesson_plan_report_form.valid?
      lesson_plan_report = DisciplineContentRecordReport.build(current_entity_configuration,
                                                               @discipline_lesson_plan_report_form.date_start,
                                                               @discipline_lesson_plan_report_form.date_end,
                                                               @discipline_lesson_plan_report_form.discipline_content_record,
                                                               current_teacher)
      send_pdf(t("routes.discipline_content_record"), lesson_plan_report.render)
    else
      @discipline_lesson_plan_report_form
      fetch_collections
      clear_invalid_dates
      render :form
    end
  end

  private

  def fetch_collections
    @number_of_classes = current_school_calendar.number_of_classes
  end

  def resource_params
    params.require(:discipline_lesson_plan_report_form).permit(
      :unity_id,
      :classroom_id,
      :discipline_id,
      :date_start,
      :date_end,
      :author
    )
  end

  def clear_invalid_dates
    begin
      resource_params[:date_start].to_date
    rescue ArgumentError
      @discipline_lesson_plan_report_form.date_start = ''
    end

    begin
      resource_params[:date_end].to_date
    rescue ArgumentError
      @discipline_lesson_plan_report_form.date_end = ''
    end
  end
end
