class Api::V1::DailyFrequenciesController < Api::V1::BaseController

  respond_to :json


  def index
    frequency_type_resolver = FrequencyTypeResolver.new(classroom, teacher)

    if frequency_type_resolver.general?
      @daily_frequencies = DailyFrequency
        .by_classroom_id(params[:classroom_id])
        .general_frequency
    else
      @daily_frequencies = DailyFrequency
        .by_classroom_id(params[:classroom_id])
        .by_discipline_id(params[:discipline_id])
    end

    @daily_frequencies = @daily_frequencies
      .by_frequency_date_between(10.days.ago, Date.today)
      .order_by_frequency_date
      .order_by_class_number

    respond_with @daily_frequencies
  end

  def create
    if params[:class_numbers].present?
      process_multiple
    else
      process_one
    end
  end

  def current_user
    User.find(user_id)
  end

  protected

  def classroom
    Classroom.find_by_id(params[:classroom_id])
  end

  def teacher
    Teacher.find_by_id(params[:teacher_id])
  end

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

      @student_enrollments.each do |student_enrollment|
        if student = Student.find_by_id(student_enrollment.student_id)
          dependence = student_has_dependence?(student_enrollment.id, @daily_frequency.discipline_id)
          @students << (@daily_frequency.students.where(student_id: student.id).first || @daily_frequency.students.create(student_id: student.id, dependence: dependence, present: true, active: true))
        end
      end
    end

    render json: @daily_frequency
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
      @student_enrollments.each do |student_enrollment|
        student = student_enrollment.student
        @daily_frequencies.map do |daily_frequency| 
          (daily_frequency.students.where(student_id: student.id).first || 
           daily_frequency.students.create(student_id: student.id,
                                           dependence: student_has_dependence?(student_enrollment.id, @daily_frequencies[0].discipline_id), 
                                           present: true,
                                           active: true))
        end
      end


      render json: @daily_frequencies


      # @students = []

      # @student_enrollments.each do |student_enrollment|
      #   student = student_enrollment.student
      #   @students << {
      #     student_id: student.id,
      #     student_name: student.name,
      #     dependence: student_has_dependence?(student_enrollment.id, @daily_frequencies[0].discipline_id),
      #     daily_frequencies: @daily_frequencies.map{ |daily_frequency| (daily_frequency.students.where(student_id: student.id).first || daily_frequency.students.create(student_id: student.id, dependence: student_has_dependence?(student_enrollment.id, @daily_frequencies[0].discipline_id), present: true, active: true)) }
      #   }
      # end
    end
  end

  def fetch_students
    frequency_date = params[:frequency_date] || Time.zone.today
    @student_enrollments = StudentEnrollment
      .includes(:student)
      .by_classroom(@daily_frequency.classroom)
      .by_discipline(@daily_frequency.discipline)
      .by_date(frequency_date)
      .active
      .ordered
  end

  def configuration
    @configuration ||= IeducarApiConfiguration.current
  end

  def current_school_calendar
    unity = Unity.find_by_id(params[:unity_id])
    classroom = Classroom.find_by_id(params[:classroom_id])
    CurrentSchoolCalendarFetcher.new(unity, classroom).fetch
  end

  def student_has_dependence?(student_enrollment_id, discipline_id)
    StudentEnrollmentDependence
      .by_student_enrollment(student_enrollment_id)
      .by_discipline(discipline_id)
      .any?
  end

  def user_id
    @user_id ||= params[:user_id] || 1
  end
end
