class Api::V1::DailyFrequenciesController < Api::V1::BaseController

  respond_to :json

  def create
    frequency_params = {
      unity_id: params[:unity_id],
      classroom_id: params[:classroom_id],
      discipline_id: params[:discipline_id],
      frequency_date: params[:frequency_date],
      class_number: params[:class_number],
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

      @student_enrollments.each do |student_enrollment|
        if student = Student.find_by_id(student_enrollment.student_id)
          dependence = student_has_dependence?(student_enrollment.id, @daily_frequency.discipline_id)
          @students << (@daily_frequency.students.where(student_id: student.id).first || @daily_frequency.students.create(student_id: student.id, dependence: dependence, present: true))
        end
      end
    end
  end

  protected

  def fetch_students
    frequency_date = params[:frequency_date] || Time.zone.today
    @student_enrollments = StudentEnrollment
      .by_classroom(@daily_frequency.classroom)
      .by_date(frequency_date)
      .active
      .ordered
  end

  def configuration
    @configuration ||= IeducarApiConfiguration.current
  end

  def current_school_calendar
    CurrentSchoolCalendarFetcher.new(params[:unity_id]).fetch
  end

  def student_has_dependence?(student_enrollment_id, discipline_id)
    StudentEnrollmentDependence
      .by_student_enrollment(student_enrollment_id)
      .by_discipline(discipline_id)
      .any?
  end
end
