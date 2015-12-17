class DailyFrequenciesController < ApplicationController
  before_action :require_teacher
  before_action :require_current_school_calendar
  before_action :set_number_of_classes, only: [:new, :create, :edit_multiple, :update_multiple]

  def new
    @daily_frequency = DailyFrequency.new.localized
    @daily_frequency.unity = current_user_unity
    @daily_frequency.frequency_date = Time.zone.today

    @class_numbers = []

    authorize @daily_frequency

    fetch_unities
  end

  def create
    @daily_frequency = DailyFrequency.new(resource_params)
    @daily_frequency.school_calendar = current_school_calendar
    @class_numbers = params[:class_numbers].split(',')

    if (@daily_frequency.valid? and validate_class_numbers)
      @daily_frequencies = []

      if @daily_frequency.global_absence?
        params = resource_params
        params[:discipline_id] = nil
        @daily_frequencies << @daily_frequency =
            DailyFrequency.find_or_create_by(unity_id: @daily_frequency.unity_id,
                                              classroom_id: @daily_frequency.classroom_id,
                                              frequency_date: @daily_frequency.frequency_date,
                                              global_absence: true,
                                              school_calendar: current_school_calendar)
      else
        @class_numbers.each do |class_number|
          params = resource_params
          params[:class_number] = class_number
          params[:school_calendar_id] = current_school_calendar.id
          params[:frequency_date] = params[:frequency_date].to_date
          @daily_frequencies << @daily_frequency = DailyFrequency.find_or_create_by(params)
        end
      end
      redirect_to edit_multiple_daily_frequencies_path(daily_frequencies_ids: @daily_frequencies.map(&:id))
    else
      fetch_unities
      render :new
    end
  end

  def edit_multiple
    @daily_frequencies = DailyFrequency.where(id: params[:daily_frequencies_ids]).order_by_class_number.includes(:students)
    @daily_frequency = @daily_frequencies.first

    authorize @daily_frequencies.first

    fetch_students

    @students = []

    students_api_codes = @api_students.map { |api_student| api_student['id'] }
    students = Student.where(api_code: students_api_codes)

    students.each do |student|
      api_student = @api_students.find { |api_student| api_student['id'] == student.api_code }
      @students << { student: student, dependence: api_student['dependencia'] }
    end

    @daily_frequencies.each do |daily_frequency|
      students_ids = daily_frequency.students.map(&:student_id)

      @students.each do |student|
        if students_ids.none? { |student_id| student_id == student[:student].id }
          daily_frequency.students.build(student_id: student[:student].id, dependence: student[:dependence])
        end
      end
    end

    @normal_students = []
    @dependence_students = []

    @students.each do |student|
      @normal_students << student[:student] if !student[:dependence]
      @dependence_students << student[:student] if student[:dependence]
    end

    @normal_students = @normal_students.sort_by { |student| student.name }
    @dependence_students = @dependence_students.sort_by { |student| student.name }
  end

  def update_multiple
    authorize DailyFrequency.new

    daily_frequency_updater = DailyFrequencyUpdater.new
    daily_frequency_updater.update(daily_frequency_student_params[:daily_frequency_student])

    flash[:success] = t 'daily_frequencies.success'

    redirect_to new_daily_frequency_path
  end

  def destroy_multiple
    @daily_frequencies = DailyFrequency.where(id: params[:daily_frequencies_ids]).order_by_class_number

    if @daily_frequencies.any?
      authorize @daily_frequencies.first

      @daily_frequencies.each { |daily_frequency| daily_frequency.destroy }

      respond_with @daily_frequencies.first, location: new_daily_frequency_path
    else
      flash[:alert] =  t('.alert')

      redirect_to new_daily_frequency_path
    end

  end

  def history
    @daily_frequency = DailyFrequency.find(params[:id])

    authorize @daily_frequency

    respond_with @daily_frequency
  end

  protected

  def fetch_students
    begin
      api = IeducarApi::Students.new(configuration.to_api)
      result = api.fetch_for_daily(
        {
          classroom_api_code: @daily_frequency.classroom.api_code,
          discipline_api_code: @daily_frequency.discipline.try(:api_code),
          date: @daily_frequency.frequency_date
        }
      )

      @api_students = result['alunos']
    rescue IeducarApi::Base::ApiError => e
      flash[:alert] = e.message
      @api_students = []
      redirect_to new_daily_frequency_path
    end
  end

  def configuration
    @configuration ||= IeducarApiConfiguration.current
  end

  def fetch_unities
    fetcher = UnitiesClassroomsDisciplinesByTeacher.new(current_teacher.id, @daily_frequency.unity_id, @daily_frequency.classroom_id, @daily_frequency.discipline_id)
    fetcher.fetch!
    @unities = fetcher.unities
    @classrooms = fetcher.classrooms
    @disciplines = fetcher.disciplines
    @avaliations = fetcher.avaliations
  end

  def resource_params
    params.require(:daily_frequency).permit(
      :unity_id, :classroom_id, :discipline_id, :global_absence, :frequency_date
    )
  end

  def daily_frequency_student_params
    params.permit(
      daily_frequency_student: [:daily_frequency_id, :student_id, :present, :dependence]
    )
  end

  def set_number_of_classes
    @number_of_classes = current_school_calendar.number_of_classes
  end

  def require_teacher
    unless current_teacher
      flash[:alert] = t('errors.daily_frequencies.require_teacher')
      redirect_to root_path
    end
  end

  def validate_class_numbers
    if !@daily_frequency.global_absence? && (@class_numbers.nil? || @class_numbers.empty?)
      @error_on_class_numbers = true
      flash.now[:alert] = t('errors.daily_frequencies.class_numbers_required_when_not_global_absence')
      return false
    end
    true
  end
end
