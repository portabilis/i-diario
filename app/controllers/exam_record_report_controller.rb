class ExamRecordReportController < ApplicationController
  before_action :require_current_classroom
  before_action :require_current_teacher

  def form
    @exam_record_report_form = ExamRecordReportForm.new(
      classroom_id: current_user_classroom.id,
      discipline_id: current_user_discipline.id
    )
    @admin_or_teacher = @admin_or_teacher

    fetch_linked_by_teacher unless @admin_or_teacher
    fetch_collections
  end

  def report
    @exam_record_report_form = ExamRecordReportForm.new(resource_params)
    fetch_collections

    if @exam_record_report_form.valid?
      exam_record_report = @school_calendar_classroom_steps.any? ? build_by_classroom_steps : build_by_school_steps
      send_pdf(t("routes.exam_record_report"), exam_record_report.render)
    else
      fetch_linked_by_teacher unless @admin_or_teacher
      fetch_collections
      render :form
    end
  end

  def fetch_step
    return if params[:classroom_id].blank?

    classroom = Classroom.find(params[:classroom_id])
    step_numbers = StepsFetcher.new(classroom)&.steps
    steps = step_numbers.map { |step| { id: step.id, description: step.to_s } }

    render json: steps.to_json
  end

  private

  def build_by_school_steps
    ExamRecordReport.build(
      current_entity_configuration,
      current_teacher,
      current_school_year,
      @exam_record_report_form.step,
      current_test_setting_step(@exam_record_report_form.step),
      @exam_record_report_form.daily_notes,
      @exam_record_report_form.students_enrollments,
      @exam_record_report_form.complementary_exams,
      @exam_record_report_form.school_term_recoveries,
      @exam_record_report_form.recovery_lowest_notes?,
      @exam_record_report_form.lowest_notes
    )
  end

  def build_by_classroom_steps
    ExamRecordReport.build(
      current_entity_configuration,
      current_teacher,
      current_school_calendar.year,
      @exam_record_report_form.classroom_step,
      current_test_setting_step(@exam_record_report_form.classroom_step),
      @exam_record_report_form.daily_notes_classroom_steps,
      @exam_record_report_form.students_enrollments,
      @exam_record_report_form.complementary_exams,
      @exam_record_report_form.school_term_recoveries,
      @exam_record_report_form.recovery_lowest_notes?,
      @exam_record_report_form.lowest_notes
    )
  end

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(current_teacher.id, current_unity, current_school_year)
    @disciplines ||= @fetch_linked_by_teacher[:disciplines]
    @classrooms ||= @fetch_linked_by_teacher[:classrooms]
  end

  def fetch_collections
    @school_calendar_steps = SchoolCalendarStep.where(school_calendar: current_school_calendar).ordered
    @school_calendar_classroom_steps = SchoolCalendarClassroomStep.by_classroom(current_user_classroom.id).ordered
  end

  def resource_params
    params.require(:exam_record_report_form).permit(:unity_id,
                                                    :classroom_id,
                                                    :discipline_id,
                                                    :school_calendar_step_id,
                                                    :school_calendar_classroom_step_id)
  end
end
