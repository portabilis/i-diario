class AttendanceRecordReportController < ApplicationController
  before_action :require_current_classroom
  before_action :require_current_teacher

  def form
    @attendance_record_report_form = AttendanceRecordReportForm.new(
      unity_id: current_unity.id,
      school_calendar_year: current_school_year,
      classroom_id: current_user_classroom.id,
      discipline_id: current_user_discipline.id,
      period: current_teacher_period
    )

    set_options_by_user
    fetch_collections
  end

  def report
    @attendance_record_report_form = AttendanceRecordReportForm.new(resource_params)
    @attendance_record_report_form.school_calendar = SchoolCalendar.find_by(
      unity: @attendance_record_report_form.unity_id,
      year: current_user_school_year
    )

    if @attendance_record_report_form.valid?
      attendance_record_report = AttendanceRecordReport.build(
        current_entity_configuration,
        current_teacher,
        current_user_school_year,
        @attendance_record_report_form.start_at,
        @attendance_record_report_form.end_at,
        @attendance_record_report_form.daily_frequencies,
        @attendance_record_report_form.enrollment_classrooms_list,
        @attendance_record_report_form.school_calendar_events,
        @attendance_record_report_form.school_calendar,
        @attendance_record_report_form.second_teacher_signature,
        @attendance_record_report_form.students_frequencies_percentage,
        current_user,
        resource_params[:classroom_id]
      )
      send_pdf(t('routes.attendance_record'), attendance_record_report.render)
    else
      @attendance_record_report_form.school_calendar_year = current_school_year

      set_options_by_user
      fetch_collections
      clear_invalid_dates
      render :form
    end
  end

  def period
    return if params[:classroom_id].blank? || params[:discipline_id].blank?

    render json: TeacherPeriodFetcher.new(
                    current_teacher.id,
                    params[:classroom_id],
                    params[:discipline_id]
                  ).teacher_period
  end

  def number_of_classes
    return if params[:classroom_id].blank?

    classroom = Classroom.find(params[:classroom_id])

    school_calendar = CurrentSchoolCalendarFetcher.new(current_unity,classroom,current_school_year).fetch

    render json: school_calendar.number_of_classes
  end

  private

  def fetch_collections
    @number_of_classes = current_school_calendar.number_of_classes
    @teacher = current_teacher
    @period = current_teacher_period
  end

  def resource_params
    params.require(:attendance_record_report_form).permit(:unity_id,
                                                          :classroom_id,
                                                          :period,
                                                          :discipline_id,
                                                          :class_numbers,
                                                          :start_at,
                                                          :end_at,
                                                          :school_calendar_year,
                                                          :current_teacher_id,
                                                          :second_teacher_signature)
  end

  def clear_invalid_dates
    start_at = resource_params[:start_at]
    end_at = resource_params[:end_at]

    @attendance_record_report_form.start_at = '' unless start_at.try(:to_date)
    @attendance_record_report_form.end_at = '' unless end_at.try(:to_date)
  end

  def current_teacher_period
    TeacherPeriodFetcher.new(
      current_teacher.id,
      current_user.current_classroom_id,
      current_user.current_discipline_id
    ).teacher_period
  end

  def set_options_by_user
    @admin_or_teacher ||= current_user.current_role_is_admin_or_employee?
    @unities ||= @admin_or_teacher ? Unity.ordered : [current_user_unity]

    return fetch_linked_by_teacher unless @admin_or_teacher

    @classrooms = Classroom.by_unity(@attendance_record_report_form.unity_id)
                           .by_year(current_user_school_year || Date.current.year)
                           .ordered
    @disciplines = Discipline.by_classroom_id(@attendance_record_report_form.classroom_id)
                             .not_descriptor
  end

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(current_teacher.id, current_unity, current_school_year)
    @classrooms = @fetch_linked_by_teacher[:classrooms]
    classroom_id = @attendance_record_report_form.classroom_id
    @disciplines = @fetch_linked_by_teacher[:disciplines].by_classroom_id(classroom_id)
                                                         .not_descriptor
  end
end
