class AttendanceRecordReportByStudentsController < ApplicationController
  before_action :require_current_classroom
  before_action :require_current_teacher

  def form
    @period ||= current_teacher_period
    @attendance_record_report_by_student_form = AttendanceRecordReportByStudentForm.new(
      unity_id: current_unity.id,
      school_calendar_year: current_school_year,
      period: @period,
      current_user_id: current_user.id
    )

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
    else
      @attendance_record_report_by_student_form.school_calendar_year = current_school_year

      set_options_by_user
      clear_invalid_dates
      render :form
    end
  end

  private

  def fetch_collections
    @unity = @attendance_record_report_by_student_form.unity
    @classrooms = @attendance_record_report_by_student_form.set_all_classrooms
    @school_calendar_year = @attendance_record_report_by_student_form.school_calendar_year
    # percentage_by_student = @attendance_record_report_by_student_form.students_frequencies_percentage
    @range_dates = "De #{report_params[:start_at]} à #{report_params[:end_at]}"

    @students = @attendance_record_report_by_student_form.enrollment_classrooms_list.map do |student_enrollment_classroom|
      student = student_enrollment_classroom[:student]
      sequence = student_enrollment_classroom[:student_enrollment_classroom].sequence
      classroom_id = student_enrollment_classroom[:student_enrollment_classroom].classrooms_grade.classroom_id
      percentage = percentage_by_student[student.id]

      {
        student_id: student.id,
        student_name: student.name,
        sequence: sequence,
        percentage: percentage,
        classroom_id: classroom_id
      }
    end
  end

  def clear_invalid_dates
    @attendance_record_report_form.start_at = parse_date(report_params[:start_at])
    @attendance_record_report_form.end_at = parse_date(report_params[:end_at])
  end

  def parse_date(date_string)
    Date.parse(date_string)
  rescue ArgumentError
    ''
  end

  def set_options_by_user
    @admin_or_teacher ||= current_user.current_role_is_admin_or_employee?
    @unities ||= @admin_or_teacher ? Unity.ordered : [current_user_unity]

    return fetch_linked_by_teacher unless @admin_or_teacher

    @classrooms = Classroom.by_unity(@attendance_record_report_by_student_form.unity_id)
                           .by_year(current_user_school_year || Date.current.year)
                           .ordered
    @disciplines = Discipline.by_classroom_id(@attendance_record_report_by_student_form.classroom_id)
  end

  def current_teacher_period
    TeacherPeriodFetcher.new(
      current_teacher.id,
      current_user_classroom.id,
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
