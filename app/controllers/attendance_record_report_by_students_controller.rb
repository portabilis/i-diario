class AttendanceRecordReportByStudentsController < ApplicationController
  before_action :require_current_classroom
  before_action :require_current_teacher

  def form
    @attendance_record_report_by_student_form = AttendanceRecordReportByStudentForm.new(
      unity_id: current_unity.id,
      school_calendar_year: current_school_year,
      period: @period,
      current_user_id: current_user.id
    )
    @period = current_teacher_period

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
    @school_calendar_year = @attendance_record_report_by_student_form.school_calendar_year
    @range_dates = "De #{report_params[:start_at]} à #{report_params[:end_at]}"
    checkbox_show_inactive_enrollments = show_inactive_enrollments

    info_students = @attendance_record_report_by_student_form.enrollment_classrooms_list.map do |student_enrollment_classroom|
      student = student_enrollment_classroom.student_enrollment.student
      sequence = student_enrollment_classroom.sequence if checkbox_show_inactive_enrollments
      classroom_id = student_enrollment_classroom.classrooms_grade.classroom_id

      {
        student_id: student.id,
        student_name: student.name,
        sequence: sequence,
        classroom_id: classroom_id
      }
    end

    classrooms = @attendance_record_report_by_student_form.set_all_classrooms
    @students_by_classrooms = classrooms.map do |classroom|
      students = info_students.select{ |student| student[:classroom_id].eql?(classroom.id) }

      next if students.empty?

      {
        classroom.id => {
          classroom_name: classroom.description,
          grade_name: classroom.grades.first.description,
          students: students.map do |student|
            {
              student_id: student[:student_id],
              student_name: student[:student_name],
              sequence: student[:sequence]
            }
          end
        }
      }
    end.compact.reduce(&:merge)
  end

  def show_inactive_enrollments
    show_inactive_enrollments = GeneralConfiguration.first.show_inactive_enrollments
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
    @admin_or_teacher = current_user.current_role_is_admin_or_employee?
    @unities = @admin_or_teacher ? Unity.ordered : [current_user_unity]

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
