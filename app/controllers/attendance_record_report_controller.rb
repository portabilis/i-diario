class AttendanceRecordReportController < ApplicationController
  before_action :require_current_teacher
  before_action :require_current_school_calendar
  before_action :require_current_test_setting

  def form
    @attendance_record_report_form = AttendanceRecordReportForm.new(school_calendar_year: current_school_calendar.year)
    fetch_collections
  end

  def report
    @attendance_record_report_form = AttendanceRecordReportForm.new(resource_params)

    if @attendance_record_report_form.valid?
      students = fetch_students
      attendance_record_report = AttendanceRecordReport.build(current_entity_configuration,
                                                              current_teacher,
                                                              current_school_calendar.year,
                                                              @attendance_record_report_form.start_at,
                                                              @attendance_record_report_form.end_at,
                                                              @attendance_record_report_form.daily_frequencies,
                                                              students)

      send_data(attendance_record_report.render, filename: 'registro-de-frequencia.pdf', type: 'application/pdf', disposition: 'inline')
    else
      @attendance_record_report_form.school_calendar_year = current_school_calendar.year
      fetch_collections
      render :form
    end
  end

  private

  def fetch_collections
    fetcher = UnitiesClassroomsDisciplinesByTeacher.new(current_teacher.id,
                                                        @attendance_record_report_form.unity_id,
                                                        @attendance_record_report_form.classroom_id,
                                                        @attendance_record_report_form.discipline_id)
    fetcher.fetch!
    @unities = fetcher.unities
    @classrooms = fetcher.classrooms
    @disciplines = fetcher.disciplines
    @number_of_classes = current_school_calendar.number_of_classes
  end

  def fetch_students
    begin
      api = IeducarApi::Students.new(IeducarApiConfiguration.current.to_api)
      classroom = Classroom.find(@attendance_record_report_form.classroom_id)

      if @attendance_record_report_form.discipline_id.present?
        discipline = Discipline.find(@attendance_record_report_form.discipline_id)
      end

      result = api.fetch_for_daily(
        {
          classroom_api_code: classroom.api_code,
          discipline_api_code: discipline.try(:api_code)
        }
      )

      api_students = result['alunos']
      students_api_codes = api_students.map { |api_student| api_student['id'] }
      students = Student.where(api_code: students_api_codes).ordered

      students
    rescue IeducarApi::Base::ApiError => e
      flash[:alert] = e.message

      render :form
    end
  end

  def resource_params
    params.require(:attendance_record_report_form).permit(:unity_id,
                                                          :classroom_id,
                                                          :discipline_id,
                                                          :class_numbers,
                                                          :start_at,
                                                          :end_at,
                                                          :school_calendar_year,
                                                          :global_absence)
  end
end