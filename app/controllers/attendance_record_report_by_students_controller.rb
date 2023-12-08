class AttendanceRecordReportByStudentsController < ApplicationController
  before_action :require_current_classroom
  before_action :require_current_teacher

  def form
    @period ||= current_teacher_period

    @attendance_record_report_by_student_form = AttendanceRecordReportByStudentForm.new(
      unity_id: current_unity.id,
      school_calendar_year: current_school_year,
      classroom_id: current_user_classroom.id,
      period: @period
    )

    set_options_by_user
  end

  private

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
end
