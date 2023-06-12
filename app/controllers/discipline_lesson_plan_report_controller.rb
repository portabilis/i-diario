class DisciplineLessonPlanReportController < ApplicationController
  DISCIPLINE_LESSON_PLAN_REPORT = "1"
  DISCIPLINE_CONTENT_RECORD = "2"

  before_action :require_current_teacher

  def form
    @discipline_lesson_plan_report_form = DisciplineLessonPlanReportForm.new
    @discipline_lesson_plan_report_form.teacher_id = current_teacher_id
    select_options_by_user
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
      select_options_by_user
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
      select_options_by_user
      clear_invalid_dates
      render :form
    end
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
    @disciplines ||= @fetch_linked_by_teacher[:disciplines]
    @classrooms ||= @fetch_linked_by_teacher[:classrooms]
  end

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
