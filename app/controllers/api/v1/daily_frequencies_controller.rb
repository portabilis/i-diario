class Api::V1::DailyFrequenciesController < Api::V1::BaseController

  respond_to :json

  def create
    if params[:class_numbers].present?
      process_multiple
    else
      process_one
    end
  end

  protected

  def process_one
    frequency_params = {
      unity_id: params[:unity_id],
      classroom_id: params[:classroom_id],
      discipline_id: params[:discipline_id],
      frequency_date: params[:frequency_date],
      class_number: params[:class_number],
      school_calendar: current_school_calendar
    }
    @daily_frequency = DailyFrequency.new(frequency_params)

    unless @daily_frequency.valid?
      render json: @daily_frequency.errors.full_messages, status: 422
    else
      @daily_frequency = DailyFrequency.find_or_create_by(frequency_params)

      fetch_students

      @students = []

      @student_ids.each do |student_id|
        if student = Student.find_by_id(student_id)
          @students << (@daily_frequency.students.where(student_id: student.id).first || @daily_frequency.students.create(student_id: student.id, dependence: false, present: true))
        end
      end
    end
  end

  def process_multiple
    frequency_params = {
      unity_id: params[:unity_id],
      classroom_id: params[:classroom_id],
      discipline_id: params[:discipline_id],
      frequency_date: params[:frequency_date],
      school_calendar: current_school_calendar
    }

    @class_numbers = params[:class_numbers].split(",")

    @daily_frequency = DailyFrequency.new(frequency_params)

    unless @daily_frequency.valid?
      render json: @daily_frequency.errors.full_messages, status: 422
    else
      @daily_frequencies = []

      @class_numbers.each do |class_number|
        @daily_frequencies << DailyFrequency.find_or_create_by(frequency_params.merge({class_number: class_number}))
      end

      fetch_students

      @students = []


      @api_students.each do |api_student|
        if student = Student.find_by(api_code: api_student['id'])
          @students << {
            student_id: student.id,
            student_name: student.name,
            dependence: api_student['dependencia'],
            daily_frequencies: @daily_frequencies.map{ |daily_frequency| (daily_frequency.students.where(student_id: student.id).first || daily_frequency.students.create(student_id: student.id, dependence: api_student['dependencia'], present: true)) }
          }
        end
      end
    end
  end

  def fetch_students
    frequency_date = params[:frequency_date] || Time.zone.today
    @student_ids = StudentEnrollment
      .by_classroom(@daily_frequency.classroom)
      .by_date(frequency_date)
      .ordered
      .collect(&:student_id)
  end

  def configuration
    @configuration ||= IeducarApiConfiguration.current
  end

  def current_school_calendar
    CurrentSchoolCalendarFetcher.new(params[:unity_id]).fetch
  end
end
