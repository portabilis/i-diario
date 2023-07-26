class KnowledgeAreaLessonPlanReportController < ApplicationController
  before_action :require_current_teacher

  def form
    @knowledge_area_lesson_plan_report_form = KnowledgeAreaLessonPlanReportForm.new(
      unity_id: current_unity.id,
      classroom_id: current_user_classroom.id
    )
    select_options_by_user
  end

  def lesson_plan_report
    @knowledge_area_lesson_plan_report_form = KnowledgeAreaLessonPlanReportForm.new(resource_params)
    @knowledge_area_lesson_plan_report_form.report_type = ContentRecordReportTypes::LESSON_PLAN

    if @knowledge_area_lesson_plan_report_form.valid?
      knowledge_area_lesson_plan_report = KnowledgeAreaLessonPlanReport.build(
        current_entity_configuration,
        @knowledge_area_lesson_plan_report_form.date_start,
        @knowledge_area_lesson_plan_report_form.date_end,
        @knowledge_area_lesson_plan_report_form.knowledge_area_lesson_plan,
        current_teacher
      )
      send_pdf(t("routes.knowledge_area_content_lesson_plan_records"), knowledge_area_lesson_plan_report.render)
    else
      @knowledge_area_lesson_plan_report_form
      clear_invalid_dates
      select_options_by_user
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
      select_options_by_user
      render :form
    end
  end

  def fetch_knowledge_areas
    return if params[:classroom_id].blank?

    knowledge_areas = KnowledgeArea.by_teacher(current_teacher_id).by_classroom_id(params[:classroom_id]).ordered

    render json: knowledge_areas.to_json
  end

  private

  def select_options_by_user
    if current_user.current_role_is_admin_or_employee?
      fetch_collections
    else
      fetch_linked_by_teacher
    end
  end

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(current_teacher.id, current_unity, current_school_year)
    @disciplines = @fetch_linked_by_teacher[:disciplines]
    @classrooms = @fetch_linked_by_teacher[:classrooms]
    @knowledge_areas = KnowledgeArea.all
  end

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
