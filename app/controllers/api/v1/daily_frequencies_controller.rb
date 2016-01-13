class Api::V1::DailyFrequenciesController < Api::V1::BaseController

  respond_to :json

  def create
    frequency_params = {
      unity_id: params[:unity_id],
      classroom_id: params[:classroom_id],
      discipline_id: params[:discipline_id],
      frequency_date: params[:frequency_date],
      class_number: params[:class_number],
      global_absence: params[:global_absence],
      school_calendar: current_school_calendar
    }
    @daily_frequency = DailyFrequency.new(frequency_params)
    @daily_frequency.valid?

    unless @daily_frequency.valid?
      render json: @daily_frequency.errors.full_messages, status: 422
    else
      @daily_frequency = DailyFrequency.find_or_create_by(frequency_params)

      fetch_students

      @students = []

      @api_students.each do |api_student|
        if student = Student.find_by(api_code: api_student['id'])
          @students << (@daily_frequency.students.where(student_id: student.id).first || @daily_frequency.students.create(student_id: student.id, dependence: api_student['dependencia'], present: true))
        end
      end
    end
  end

  protected

  def fetch_students
    begin
      api = IeducarApi::Students.new(configuration.to_api)
      result = api.fetch_for_daily(
        {
          classroom_api_code: @daily_frequency.classroom.api_code,
          discipline_api_code: @daily_frequency.discipline.try(:api_code),
          date: params[:frequency_date] || Time.zone.today
        }
      )

      @api_students = result["alunos"]
    rescue IeducarApi::Base::ApiError => e
      @api_students = []
    end
  end

  def configuration
    @configuration ||= IeducarApiConfiguration.current
  end

  def current_school_calendar
    CurrentSchoolCalendarFetcher.new(params[:unity_id]).fetch
  end
end
