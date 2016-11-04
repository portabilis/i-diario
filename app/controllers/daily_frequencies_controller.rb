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

    fetch_avaliations
  end

  def create
    @daily_frequency = DailyFrequency.new(resource_params)
    @daily_frequency.school_calendar = current_school_calendar
    @class_numbers = params[:class_numbers].split(',')
    @discipline = params[:daily_frequency][:discipline_id]

    if (@daily_frequency.valid? and validate_class_numbers and validate_discipline)
      @daily_frequencies = []

      absence_type_definer = FrequencyTypeDefiner.new(@daily_frequency.classroom, current_teacher)
      absence_type_definer.define!

      if absence_type_definer.frequency_type == FrequencyTypes::GENERAL
        @daily_frequencies = create_global_frequencies(resource_params)
      else
        @daily_frequencies = create_discipline_frequencies(resource_params)
      end
      redirect_to edit_multiple_daily_frequencies_path(daily_frequencies_ids: @daily_frequencies.map(&:id))
    else
      fetch_avaliations
      render :new
    end
  end

  def edit_multiple
    @daily_frequencies = DailyFrequency.where(id: params[:daily_frequencies_ids]).order_by_class_number.includes(:students)
    @daily_frequency = @daily_frequencies.first

    authorize @daily_frequency

    fetch_student_enrollments

    @students = []

    @student_enrollments.each do |student_enrollment|
      student = Student.find_by_id(student_enrollment.student_id) || nil
      dependence = student_has_dependence?(student_enrollment, @daily_frequency.discipline)
      @students << { student: student, dependence: dependence } if student
    end

    create_unpersisted_students
    destroy_not_existing_students

    @normal_students = []
    @dependence_students = []

    @students.each do |student|
      @normal_students << student[:student] if !student[:dependence]
      @dependence_students << student[:student] if student[:dependence]
    end
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

  def create_unpersisted_students
    @daily_frequencies.each do |daily_frequency|
      persisted_student_ids = daily_frequency.students.map(&:student_id)

      @students.each do |student|
        if persisted_student_ids.none? { |student_id| student_id == student[:student].id }
          daily_frequency.students.create(student_id: student[:student].id, dependence: student[:dependence], present: true)
        end
      end
    end
  end

  def destroy_not_existing_students
    current_students_ids = @students.map{|student| student[:student].id}

    @daily_frequencies.each do |daily_frequency|
      daily_frequency.students.each do |daily_frequency_student|
        daily_frequency_student.destroy! unless current_students_ids.include? daily_frequency_student.student.id
      end
    end
  end

  def fetch_student_enrollments
    @student_enrollments = StudentEnrollment
      .by_classroom(@daily_frequency.classroom)
      .by_date(@daily_frequency.frequency_date)
      .active
      .ordered
  end

  def configuration
    @configuration ||= IeducarApiConfiguration.current
  end

  def fetch_avaliations
    fetcher = UnitiesClassroomsDisciplinesByTeacher.new(current_teacher.id, @daily_frequency.unity_id, @daily_frequency.classroom_id, @daily_frequency.discipline_id)
    fetcher.fetch!
    @avaliations = fetcher.avaliations
  end

  def resource_params
    params.require(:daily_frequency).permit(
      :unity_id, :classroom_id, :discipline_id, :frequency_date
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
    absence_type_definer = FrequencyTypeDefiner.new(@daily_frequency.classroom, current_teacher)
    absence_type_definer.define!

    if (absence_type_definer.frequency_type == FrequencyTypes::BY_DISCIPLINE) && (@class_numbers.nil? || @class_numbers.empty?)
      @error_on_class_numbers = true
      flash.now[:alert] = t('errors.daily_frequencies.class_numbers_required_when_not_global_absence')
      return false
    end
    true
  end

  def validate_discipline
    absence_type_definer = FrequencyTypeDefiner.new(@daily_frequency.classroom, current_teacher)
    absence_type_definer.define!

    if (absence_type_definer.frequency_type == FrequencyTypes::BY_DISCIPLINE) && (@discipline.nil? || @discipline.empty?)
      @error_on_discipline = true
      flash.now[:alert] = t('errors.daily_frequencies.discipline_required_when_not_global_absence')
      return false
    end
    true
  end

  def create_global_frequencies(params)
    daily_frequencies = []
    params[:school_calendar] = current_school_calendar
    params[:discipline_id] = nil
    params[:class_number] = nil
    daily_frequencies << DailyFrequency.find_or_create_by(params)
    daily_frequencies
  end

  def create_discipline_frequencies(params)
    daily_frequencies = []
    @class_numbers.each do |class_number|
      params = resource_params
      params[:class_number] = class_number
      params[:school_calendar_id] = current_school_calendar.id
      params[:frequency_date] = params[:frequency_date].to_date
      daily_frequencies << DailyFrequency.find_or_create_by(params)
    end
    daily_frequencies
  end

  def student_has_dependence?(student_enrollment, discipline)
    StudentEnrollmentDependence
      .by_student_enrollment(student_enrollment)
      .by_discipline(discipline)
      .any?
  end
end
