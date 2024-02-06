class AttendanceRecordReportByStudentsController < ApplicationController
  before_action :require_current_classroom
  before_action :require_current_teacher

  def form
    @attendance_record_report_by_student_form = AttendanceRecordReportByStudentForm.new(
      unity_id: current_unity.id,
      school_calendar_year: current_school_year,
      period: adjusted_period,
      current_user_id: current_user.id,
      classroom_id: current_user_classroom.id
    )
    @period = current_teacher_period(current_user_classroom.id)

    set_options_by_user
  end

  def report
    @attendance_record_report_by_student_form = AttendanceRecordReportByStudentForm.new(report_params)
    @attendance_record_report_by_student_form.school_calendar = SchoolCalendar.find_by(
      unity: @attendance_record_report_by_student_form.unity_id,
      year: current_user_school_year
    )

    if @attendance_record_report_by_student_form.valid?
      fetch_collections
      response = ReportGenerator.call(render_to_string(action: :report, layout: "report"))
      send_data response.body, filename: @attendance_record_report_by_student_form.filename,
        type: "application/pdf", disposition: "attachment"
    else
      @attendance_record_report_by_student_form.school_calendar_year = current_school_year

      set_options_by_user
      render :form
    end
  end

  def fetch_period_by_classroom
    return if params[:classroom_id].blank?

    classroom_id = Classroom.find_by(id: params[:classroom_id])&.id

    return if classroom_id.blank?

    render json: current_teacher_period(classroom_id)
  end

  private

  def fetch_collections
    @unity = @attendance_record_report_by_student_form.unity
    @school_calendar_year = @attendance_record_report_by_student_form.school_calendar_year
    @range_dates = "De #{report_params[:start_at]} à #{report_params[:end_at]}"

    classrooms = @attendance_record_report_by_student_form.select_all_classrooms
    enrollment_classrooms_list = @attendance_record_report_by_student_form.enrollment_classrooms_list
    @students_by_classrooms ||= AttendanceRecordReportByStudent.call(
      classrooms,
      enrollment_classrooms_list,
      @attendance_record_report_by_student_form.period,
      @attendance_record_report_by_student_form.start_at,
      @attendance_record_report_by_student_form.end_at
    )
  end

  def set_options_by_user
    @admin_or_teacher = current_user.current_role_is_admin_or_employee?
    @unities = @admin_or_teacher ? Unity.ordered : [current_user_unity]

    return fetch_linked_by_teacher unless @admin_or_teacher

    @classrooms = Classroom.by_unity(@attendance_record_report_by_student_form.unity_id)
                           .by_year(current_user_school_year || Date.current.year)
                           .ordered
    @disciplines = Discipline.by_classroom_id(@attendance_record_report_by_student_form.classroom_id)
  end

  def adjusted_period
    return Periods::FULL if @period.eql?('all') || @period.eql?(Periods::FULL)

    @period
  end

  def current_teacher_period(classroom_id)
    TeacherPeriodFetcher.new(
      current_teacher.id,
      classroom_id,
      nil
    ).teacher_period
  end

  def report_params
    params.require(:attendance_record_report_by_student_form).permit(
      :unity_id,
      :classroom_id,
      :period,
      :start_at,
      :end_at,
      :school_calendar_year,
      :current_teacher_id,
      :current_user_id
    )
  end
end
