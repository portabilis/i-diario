class DailyFrequenciesController < ApplicationController
  before_action :require_teacher
  before_action :set_number_of_classes, only: [:new, :create, :edit_multiple, :update_multiple]

  def new
    @daily_frequency = DailyFrequency.new.localized
    @daily_frequency.unity = current_user_unity
    @daily_frequency.frequency_date = Time.zone.today
    @class_numbers = []
    @period = current_teacher_period

    authorize @daily_frequency
  end

  def create
    @daily_frequency = DailyFrequency.new(resource_params)
    @daily_frequency.school_calendar = current_school_calendar
    @class_numbers = params[:class_numbers].split(',')
    @daily_frequency.class_number = @class_numbers.first
    @discipline = params[:daily_frequency][:discipline_id]
    @period = params[:daily_frequency][:period]

    if validate_class_numbers && validate_discipline && @daily_frequency.valid?
      absence_type_definer = FrequencyTypeDefiner.new(@daily_frequency.classroom,
                                                      current_teacher,
                                                      year: @daily_frequency.classroom.year)
      absence_type_definer.define!

      @daily_frequencies = create_global_frequencies if absence_type_definer.frequency_type == FrequencyTypes::GENERAL
      @daily_frequencies ||= create_discipline_frequencies

      redirect_to edit_multiple_daily_frequencies_path(daily_frequencies_ids: @daily_frequencies.map(&:id))
    else
      clear_invalid_date

      render :new
    end
  end

  def edit_multiple
    @daily_frequencies = DailyFrequency.where(id: params[:daily_frequencies_ids]).order_by_class_number.includes(:students)
    @daily_frequency = @daily_frequencies.first
    teacher_period = current_teacher_period
    @period = teacher_period != Periods::FULL.to_i ? teacher_period : nil

    authorize @daily_frequency

    student_enrollments = fetch_student_enrollments

    @students = []

    @any_exempted_from_discipline = false

    student_enrollments.each do |student_enrollment|
      student = Student.find_by_id(student_enrollment.student_id) || nil
      next unless student

      dependence = student_has_dependence?(student_enrollment, @daily_frequency.discipline)
      exempted_from_discipline = student_exempted_from_discipline?(student_enrollment, @daily_frequency)
      @any_exempted_from_discipline ||= exempted_from_discipline
      active = student_active_on_date?(student_enrollment)

      @students << {
        student: student,
        dependence: dependence,
        active: active,
        exempted_from_discipline: exempted_from_discipline
      }
    end

    create_unpersisted_students
    destroy_not_existing_students

    @normal_students = []
    @dependence_students = []

    @any_inactive_student = any_inactive_student?

    @students.each do |student|
      @normal_students << student if !student[:dependence]
      @dependence_students << student if student[:dependence]
    end
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

  def history_multiple
    @daily_frequencies = DailyFrequency.where(id: params[:daily_frequencies_ids])

    respond_with @daily_frequencies
  end

  private

  def current_teacher_period
    TeacherPeriodFetcher.new(
      current_teacher.id,
      current_user.current_classroom_id,
      current_user.current_discipline_id
    ).teacher_period
  end

  def create_unpersisted_students
    @daily_frequencies.each do |daily_frequency|
      persisted_student_ids = daily_frequency.students.map(&:student_id)

      @students.each do |student|
        next if student[:exempted_from_discipline]
        if persisted_student_ids.none? { |student_id| student_id == student[:student].id }
          begin
            daily_frequency.students.create(
              student_id: student[:student].id,
              dependence: student[:dependence],
              present: true,
              active: student[:active]
            )
          rescue ActiveRecord::RecordNotUnique
          end
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
    StudentEnrollmentsList.new(
      classroom: @daily_frequency.classroom,
      discipline: @daily_frequency.discipline,
      date: @daily_frequency.frequency_date,
      search_type: :by_date,
      period: @period
    ).student_enrollments
  end

  def student_active_on_date?(student_enrollment)
    StudentEnrollment.where(id: student_enrollment)
                     .by_classroom(@daily_frequency.classroom)
                     .by_date(@daily_frequency.frequency_date)
                     .any?
  end

  def fetch_avaliations
    fetcher = UnitiesClassroomsDisciplinesByTeacher.new(
      current_teacher.id,
      @daily_frequency.unity_id,
      @daily_frequency.classroom_id,
      @daily_frequency.discipline_id
    )
    fetcher.fetch!
    @avaliations = fetcher.avaliations
  end

  def resource_params
    params.require(:daily_frequency).permit(
      :unity_id, :classroom_id, :discipline_id, :frequency_date, :period
    )
  end

  def daily_frequency_student_params
    params.permit(
      daily_frequency_student: [:daily_frequency_id, :student_id, :present, :dependence, :active]
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
    absence_type_definer = FrequencyTypeDefiner.new(@daily_frequency.classroom,
                                                    current_teacher,
                                                    year: @daily_frequency.classroom.year)
    absence_type_definer.define!

    if (absence_type_definer.frequency_type == FrequencyTypes::BY_DISCIPLINE) && (@class_numbers.nil? || @class_numbers.empty?)
      @error_on_class_numbers = true
      flash.now[:alert] = t('errors.daily_frequencies.class_numbers_required_when_not_global_absence')
      return false
    end

    true
  end

  def validate_discipline
    absence_type_definer = FrequencyTypeDefiner.new(@daily_frequency.classroom,
                                                    current_teacher,
                                                    year: @daily_frequency.classroom.year)
    absence_type_definer.define!

    if (absence_type_definer.frequency_type == FrequencyTypes::BY_DISCIPLINE) && (@discipline.nil? || @discipline.empty?)
      @error_on_discipline = true
      flash.now[:alert] = t('errors.daily_frequencies.discipline_required_when_not_global_absence')
      return false
    end

    true
  end

  def create_global_frequencies
    params = resource_params
    params[:discipline_id] = nil
    params[:class_number] = nil
    params[:period] = @period

    [find_by_or_create_daily_frequency(params)]
  end

  def create_discipline_frequencies
    daily_frequencies = []

    @class_numbers.each do |class_number|
      params = resource_params
      params[:class_number] = class_number
      params[:period] = @period

      daily_frequencies << find_by_or_create_daily_frequency(params)
    end

    daily_frequencies
  end

  def find_by_or_create_daily_frequency(params)
    DailyFrequency.create_with(
      params.slice(
        :unity_id,
        :period
      ).merge(
        origin: OriginTypes::WEB,
        school_calendar_id: current_school_calendar.id
      )
    ).find_or_create_by(
      params.slice(
        :classroom_id,
        :frequency_date,
        :discipline_id,
        :class_number,
        :period
      )
    )
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def student_has_dependence?(student_enrollment, discipline)
    StudentEnrollmentDependence.by_student_enrollment(student_enrollment)
                               .by_discipline(discipline)
                               .any?
  end

  def student_exempted_from_discipline?(student_enrollment, daily_frequency)
    return false unless daily_frequency.discipline_id.present?

    discipline_id = daily_frequency.discipline.id
    frequency_date = daily_frequency.frequency_date
    step_number = daily_frequency.school_calendar.step(frequency_date).try(:to_number)

    student_enrollment.exempted_disciplines.by_discipline(discipline_id)
                                           .by_step_number(step_number)
                                           .any?
  end

  def any_inactive_student?
    (@students || []).any? { |student| !student[:active] }
  end

  def clear_invalid_date
    begin
      resource_params[:frequency_date].to_date
    rescue ArgumentError
      @daily_frequency.frequency_date = ''
    end
  end
end
