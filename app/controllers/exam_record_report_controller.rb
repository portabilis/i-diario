class ExamRecordReportController < ApplicationController
  before_action :require_current_classroom
  before_action :require_current_teacher

  def form
    @exam_record_report_form = ExamRecordReportForm.new
    if current_user.current_role_is_admin_or_employee?
      fetch_collections
    else
      fetch_linked_by_teacher
    end
  end

  def fetch_step
    return if params[:classroom_id].blank?

    classroom = Classroom.find(params[:classroom_id])

    school_calendar = CurrentSchoolCalendarFetcher.new(current_unity, classroom, current_school_year).fetch

    school_calendar_steps = SchoolCalendarStep.where(school_calendar: school_calendar)
    school_calendar_classroom_steps = SchoolCalendarClassroomStep.by_classroom(classroom.id).ordered

    if school_calendar_classroom_steps.any?
      step = school_calendar_classroom_steps
    else
      step = school_calendar_steps
    end
    #erro undefined method `test_setting'
    render json: step
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
    @disciplines = @fetch_linked_by_teacher[:disciplines]
    @classrooms = @fetch_linked_by_teacher[:classrooms]
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
