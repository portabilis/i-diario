class AttendanceRecordReportController < ApplicationController
  before_action :require_current_clasroom
  before_action :require_current_teacher

  def form
    @attendance_record_report_form = AttendanceRecordReportForm.new(
      unity_id: current_unity.id,
      period: current_teacher_period,
      school_calendar_year: current_school_year
    )
    fetch_collections
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
        @attendance_record_report_form.students_enrollments,
        @attendance_record_report_form.school_calendar_events,
        current_school_calendar,
        @attendance_record_report_form.second_teacher_signature,
        @attendance_record_report_form.display_knowledge_area_as_discipline
      )
      send_pdf(t('routes.attendance_record'), attendance_record_report.render)
    else
      @attendance_record_report_form.school_calendar_year = current_school_year
      fetch_collections
      clear_invalid_dates
      render :form
    end
  end

  private

  def fetch_collections
    @number_of_classes = current_school_calendar.number_of_classes
    @teacher = current_teacher
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
                                                          :second_teacher_signature,
                                                          :display_knowledge_area_as_discipline)
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
