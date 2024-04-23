class DisciplineLessonPlanReportController < ApplicationController
  DISCIPLINE_LESSON_PLAN_REPORT = "1"
  DISCIPLINE_CONTENT_RECORD = "2"

  before_action :require_current_classroom, only: [:form, :lesson_plan_report, :content_record_report]
  before_action :require_current_teacher

  def form
    @discipline_lesson_plan_report_form = DisciplineLessonPlanReportForm.new(
      teacher_id: current_teacher_id,
      unity_id: current_user_unity.id,
      classroom_id: current_user_classroom.id,
      discipline_id: current_user_discipline.id
    )

    set_options_by_user
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
      set_options_by_user
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
      set_options_by_user
      clear_invalid_dates

      render :form
    end
  end

  private

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
    date_start = resource_params[:date_start]
    date_end = resource_params[:date_end]

    @discipline_lesson_plan_report_form.date_start = '' unless date_start.try(:to_date)
    @discipline_lesson_plan_report_form.date_end = '' unless date_end.try(:to_date)
  end

  def set_options_by_user
    @admin_or_teacher ||= current_user.current_role_is_admin_or_employee?
    @unities ||= @admin_or_teacher ? Unity.ordered : [current_user_unity]

    return fetch_linked_by_teacher unless @admin_or_teacher

    fetch_collections
  end

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(
      current_teacher.id,
      current_unity,
      current_school_year
    )
    @classrooms ||= @fetch_linked_by_teacher[:classrooms]
    @disciplines ||= @fetch_linked_by_teacher[:disciplines].by_classroom_id(
      @discipline_lesson_plan_report_form.classroom_id
    ).not_descriptor
  end

  def fetch_collections
    @number_of_classes = current_school_calendar.number_of_classes
    @classrooms ||= Classroom.by_unity(@discipline_lesson_plan_report_form.unity_id)
                             .by_year(current_user_school_year || Date.current.year)
                             .ordered
    @disciplines ||= Discipline.by_classroom_id(@discipline_lesson_plan_report_form.classroom_id)
                               .not_descriptor
  end
end
