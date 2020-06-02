class KnowledgeAreaLessonPlanReportController < ApplicationController
  before_action :require_current_teacher

  def form
    @knowledge_area_lesson_plan_report_form = KnowledgeAreaLessonPlanReportForm.new(unity_id: current_unity.id)
    fetch_collections
  end

  def lesson_plan_report
    @knowledge_area_lesson_plan_report_form = KnowledgeAreaLessonPlanReportForm.new(resource_params)
    @knowledge_area_lesson_plan_report_form.report_type = ContentRecordReportTypes::LESSON_PLAN

    if @knowledge_area_lesson_plan_report_form.valid?
      knowledge_area_lesson_plan_report = KnowledgeAreaLessonPlanReport.build(current_entity_configuration,
                                                                              @knowledge_area_lesson_plan_report_form.date_start,
                                                                              @knowledge_area_lesson_plan_report_form.date_end,
                                                                              @knowledge_area_lesson_plan_report_form.knowledge_area_lesson_plan,
                                                                              current_teacher)
      send_pdf(t("routes.knowledge_area_content_lesson_plan_records"), knowledge_area_lesson_plan_report.render)
    else
      @knowledge_area_lesson_plan_report_form
      clear_invalid_dates
      fetch_collections
      render :form
    end
  end

  def content_record_report
    @knowledge_area_lesson_plan_report_form = KnowledgeAreaLessonPlanReportForm.new(resource_params)
    @knowledge_area_lesson_plan_report_form.report_type = ContentRecordReportTypes::CONTENT_RECORD

    if @knowledge_area_lesson_plan_report_form.valid?
      knowledge_area_lesson_plan_report = KnowledgeAreaContentRecordReport.build(current_entity_configuration,
                                                                                 @knowledge_area_lesson_plan_report_form.date_start,
                                                                                 @knowledge_area_lesson_plan_report_form.date_end,
                                                                                 @knowledge_area_lesson_plan_report_form.knowledge_area_content_record,
                                                                                 current_teacher)
      send_pdf(t("routes.knowledge_area_lesson_plan_record"), knowledge_area_lesson_plan_report.render)
    else
      @knowledge_area_lesson_plan_report_form
      clear_invalid_dates
      fetch_collections
      render :form
    end
  end

  private

  def fetch_collections
    @number_of_classes = current_school_calendar.number_of_classes
    @knowledge_areas = KnowledgeArea.all
  end

  def resource_params
    params.require(:knowledge_area_lesson_plan_report_form).permit(
      :unity_id,
      :teacher_id,
      :classroom_id,
      :date_start,
      :date_end,
      :knowledge_area_id,
      :author
    )
  end

  def clear_invalid_dates
    begin
      resource_params[:date_start].to_date
    rescue ArgumentError
      @knowledge_area_lesson_plan_report_form.date_start = ''
    end

    begin
      resource_params[:date_end].to_date
    rescue ArgumentError
      @knowledge_area_lesson_plan_report_form.date_end = ''
    end
  end
end
