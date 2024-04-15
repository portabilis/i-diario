class KnowledgeAreaLessonPlanReportController < ApplicationController
  before_action :require_current_teacher
  before_action :require_current_classroom, only: [:form, :lesson_plan_report, :content_record_report]

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
    @admin_or_teacher ||= current_user.current_role_is_admin_or_employee?
    @unities ||= @admin_or_teacher ? Unity.ordered : [current_user_unity]
    @knowledge_areas ||= KnowledgeArea.by_teacher(current_teacher_id)
                                      .by_classroom_id(current_user_classroom.id)
                                      .ordered

    return fetch_linked_by_teacher unless @admin_or_teacher

    fetch_collections
  end

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(current_teacher.id, current_unity, current_school_year)
    @classrooms = @fetch_linked_by_teacher[:classrooms]
  end

  def fetch_collections
    @number_of_classes = current_school_calendar.number_of_classes
    @knowledge_areas = KnowledgeArea.all
    @classrooms = Classroom.by_unity_id(@knowledge_area_lesson_plan_report_form.unity_id)
                           .by_year(current_user_school_year || Date.current.year)
                           .ordered
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
    date_start = resource_params[:date_start]
    date_end = resource_params[:date_end]

    @knowledge_area_lesson_plan_report_form.date_start = '' unless date_start.try(:to_date)
    @knowledge_area_lesson_plan_report_form.date_end = '' unless date_end.try(:to_date)
  end
end
