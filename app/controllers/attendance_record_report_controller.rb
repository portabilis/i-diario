class AttendanceRecordReportController < ApplicationController
  before_action :require_current_classroom
  before_action :require_current_teacher

  def form
    if current_user.current_role_is_admin_or_employee?
      @period = current_teacher_period
      fetch_collections
    else
      fetch_linked_by_teacher
    end

    @teacher = current_teacher
    @attendance_record_report_form = AttendanceRecordReportForm.new(
      unity_id: current_unity.id,
      school_calendar_year: current_school_year,
      period: @period
    )
  end

  def report
    @attendance_record_report_form = AttendanceRecordReportForm.new(resource_params)
    @attendance_record_report_form.school_calendar = SchoolCalendar.find_by(
      unity: current_unity,
      year: current_school_year
    )

    if @attendance_record_report_form.valid?
      attendance_record_report = AttendanceRecordReport.build(
        current_entity_configuration,
        current_teacher,
        current_school_year,
        @attendance_record_report_form.start_at,
        @attendance_record_report_form.end_at,
        @attendance_record_report_form.daily_frequencies,
        @attendance_record_report_form.enrollment_classrooms_list,
        @attendance_record_report_form.school_calendar_events,
        @attendance_record_report_form.school_calendar,
        @attendance_record_report_form.second_teacher_signature,
        @attendance_record_report_form.students_frequencies_percentage
      )
      send_pdf(t('routes.attendance_record'), attendance_record_report.render)
    else
      @attendance_record_report_form.school_calendar_year = current_school_year
      
      if current_user.current_role_is_admin_or_employee?
        @period = current_teacher_period
        @number_of_classes = current_school_calendar.number_of_classes
      else
        fetch_linked_by_teacher
      end

      @teacher = current_teacher
      clear_invalid_dates
      render :form
    end
  end

  def fetch_collections
    @number_of_classes = current_school_calendar.number_of_classes
    @teacher = current_teacher
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

  def attendance_record_report_form
   
  end

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(current_teacher.id, current_unity, current_school_year)
    @disciplines = @fetch_linked_by_teacher[:disciplines]
    @classrooms = @fetch_linked_by_teacher[:classrooms]
  end

  def clear_invalid_dates
    begin
      resource_params[:start_at].to_date
    rescue ArgumentError
      @attendance_record_report_form.start_at = ''
    end

    begin
      resource_params[:end_at].to_date
    rescue ArgumentError
      @attendance_record_report_form.end_at = ''
    end
  end

  def current_teacher_period
    TeacherPeriodFetcher.new(
      current_teacher.id,
      current_user.current_classroom_id,
      current_user.current_discipline_id
    ).teacher_period
  end
end
