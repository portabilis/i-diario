class DailyFrequenciesController < ApplicationController
  PRESENCE_DEFAULT = '0'.freeze

  before_action :require_teacher
  before_action :require_current_clasroom
  before_action :set_number_of_classes, only: [:new, :create, :edit_multiple]
  before_action :require_allow_to_modify_prev_years, only: [:create, :destroy_multiple]

  def new
    @daily_frequency = DailyFrequency.new.localized
    @daily_frequency.unity = current_user_unity
    @daily_frequency.frequency_date = Date.current
    @class_numbers = []
    @period = current_teacher_period

    authorize @daily_frequency
  end

  def create
    @daily_frequency = DailyFrequency.new(daily_frequency_params)
    @daily_frequency.school_calendar = current_school_calendar
    @daily_frequency.teacher_id = current_teacher_id
    @class_numbers = params[:class_numbers].split(',')
    @daily_frequency.class_number = @class_numbers.first
    @discipline = params[:daily_frequency][:discipline_id]
    @period = params[:daily_frequency][:period]

    if @daily_frequency.valid?
      frequency_type = current_frequency_type(@daily_frequency)

      return if frequency_type == FrequencyTypes::BY_DISCIPLINE && !(validate_class_numbers && validate_discipline)

      redirect_to edit_multiple_daily_frequencies_path(
        daily_frequency: daily_frequency_params,
        class_numbers: @class_numbers
      )
    else
      render :new
    end
  end

  def edit_multiple
    @daily_frequencies = find_or_initialize_daily_frequencies(params[:class_numbers])
    @daily_frequency = @daily_frequencies.first
    teacher_period = current_teacher_period
    @period = teacher_period != Periods::FULL.to_i ? teacher_period : nil

    authorize @daily_frequency

    @students = []
    @any_exempted_from_discipline = false
    @any_inactive_student = false

    fetch_student_enrollments.each do |student_enrollment|
      student = Student.find_by(id: student_enrollment.student_id)

      next if student.blank?

      dependence = student_has_dependence?(student_enrollment, @daily_frequency.discipline)
      exempted_from_discipline = student_exempted_from_discipline?(student_enrollment, @daily_frequency)
      @any_exempted_from_discipline ||= exempted_from_discipline
      active = student_active_on_date?(student_enrollment)
      @any_inactive_student ||= !active

      @students << {
        student: student,
        dependence: dependence,
        active: active,
        exempted_from_discipline: exempted_from_discipline
      }
    end

    build_daily_frequency_students
    mark_for_destruction_not_existing_students

    @normal_students = @students.reject { |student| student[:dependence] }
    @dependence_students = @students.select { |student| student[:dependence] }

    flash.now[:warning] = t('.warning_need_to_click_on_save') if flash.blank?
  end

  def create_or_update_multiple
    class_numbers = []
    daily_frequency_attributes = daily_frequency_params
    daily_frequency_attributes[:discipline_id] = daily_frequency_attributes[:discipline_id].presence

    begin
      ActiveRecord::Base.transaction do
        daily_frequency_id = nil

        daily_frequencies_params.each do |daily_frequency|
          class_number = daily_frequency.second[:class_number]
          class_number = class_number.to_i.zero? ? nil : class_number
          class_numbers << class_number if class_number.present?
          daily_frequency_attributes = daily_frequency_attributes.merge(class_number: class_number)
          daily_frequency.second[:class_number] = class_number

          daily_frequency.second[:students_attributes].each do |_key, daily_frequency_student|
            daily_frequency_student[:present] = PRESENCE_DEFAULT if daily_frequency_student[:present].blank?
          end

          daily_frequency_students_params = daily_frequency.second
          daily_frequency_record = find_or_initialize_daily_frequency_by(daily_frequency_attributes)
          daily_frequency_record.assign_attributes(daily_frequency_students_params)

          daily_frequency_record.save

          daily_frequency_id ||= daily_frequency_record.id
        end

        flash[:success] = t('.daily_frequency_success')

        UniqueDailyFrequencyStudentsCreator.call_worker(
          current_entity.id,
          daily_frequency_id,
          current_teacher_id
        )
      end
    rescue StandardError => error
      Honeybadger.notify(error)

      flash[:alert] = t('.daily_frequency_error')
    end

    edit_multiple_daily_frequencies_path = edit_multiple_daily_frequencies_path(
      daily_frequency: daily_frequency_attributes.slice(
        :classroom_id,
        :discipline_id,
        :frequency_date,
        :period,
        :unity_id
      ),
      class_numbers: class_numbers
    )

    redirect_to edit_multiple_daily_frequencies_path

    receive_email_confirmation = ActiveRecord::Type::Boolean.new.type_cast_from_user(
      params[:daily_frequency][:receive_email_confirmation]
    )

    return unless flash[:success].present? && receive_email_confirmation

    ReceiptMailer.delay.notify_daily_frequency_success(
      current_user,
      "#{request.base_url}#{edit_multiple_daily_frequencies_path}",
      daily_frequency_attributes[:frequency_date].to_date.strftime('%d/%m/%Y')
    )
  end

  def destroy_multiple
    @daily_frequencies = DailyFrequency.where(id: params[:daily_frequencies_ids])

    if @daily_frequencies.any?
      authorize @daily_frequencies.first

      @daily_frequencies.each(&:destroy)

      respond_with @daily_frequencies.first, location: new_daily_frequency_path
    else
      flash[:alert] = t('.alert')

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

  def daily_frequency_params
    params.require(:daily_frequency).permit(
      :unity_id, :classroom_id, :frequency_date, :discipline_id, :period
    )
  end

  def daily_frequencies_params
    params.require(:daily_frequency).permit(
      daily_frequencies: [
        :class_number,
        students_attributes: [
          [:id, :daily_frequency_id, :student_id, :present, :dependence, :active]
        ]
      ]
    ).require(:daily_frequencies)
  end

  def current_frequency_type(daily_frequency)
    absence_type_definer = FrequencyTypeDefiner.new(
      daily_frequency.classroom,
      current_teacher,
      year: daily_frequency.classroom.year
    )
    absence_type_definer.define!

    absence_type_definer.frequency_type
  end

  def validate_class_numbers
    return true if @class_numbers.present?

    @error_on_class_numbers = true
    flash.now[:alert] = t('errors.daily_frequencies.class_numbers_required_when_not_global_absence')

    false
  end

  def validate_discipline
    return true if @discipline.present?

    @error_on_discipline = true
    flash.now[:alert] = t('errors.daily_frequencies.discipline_required_when_not_global_absence')

    false
  end

  def find_or_initialize_daily_frequencies(class_numbers)
    return find_or_initialize_global_frequencies if class_numbers.blank?

    find_or_initialize_discipline_frequencies(class_numbers)
  end

  def find_or_initialize_global_frequencies
    params = daily_frequency_params
    params[:discipline_id] = nil
    params[:class_number] = nil

    [find_or_initialize_daily_frequency_by(params)]
  end

  def find_or_initialize_discipline_frequencies(class_numbers)
    daily_frequencies = []

    class_numbers.each do |class_number|
      params = daily_frequency_params
      params[:class_number] = class_number

      daily_frequencies << find_or_initialize_daily_frequency_by(params)
    end

    daily_frequencies
  end

  def find_or_initialize_daily_frequency_by(params)
    daily_frequency = DailyFrequency.find_or_initialize_by(
      params.slice(
        :classroom_id,
        :frequency_date,
        :discipline_id,
        :class_number,
        :period
      )
    ).tap do |daily_frequency_record|
      daily_frequency_record.unity_id = params[:unity_id]
      daily_frequency_record.school_calendar_id = current_school_calendar.id
      daily_frequency_record.teacher_id = current_teacher_id
      daily_frequency_record.origin = OriginTypes::WEB
    end

    @new_record ||= daily_frequency.new_record?

    daily_frequency
  end

  def current_teacher_period
    TeacherPeriodFetcher.new(
      current_teacher.id,
      current_user.current_classroom_id,
      current_user.current_discipline_id
    ).teacher_period
  end

  def build_daily_frequency_students
    @daily_frequencies.each do |daily_frequency|
      current_student_ids = daily_frequency.students.map(&:student_id)

      @students.each do |student|
        next if student[:exempted_from_discipline]
        next if current_student_ids.any? { |student_id| student_id == student[:student].id }

        daily_frequency.students.build(
          student_id: student[:student].id,
          dependence: student[:dependence],
          present: true,
          active: student[:active]
        )
      end
    end
  end

  def mark_for_destruction_not_existing_students
    current_student_ids = @students.map { |student| student[:student].id }

    @daily_frequencies.each do |daily_frequency|
      daily_frequency_students = daily_frequency.students.reject { |daily_frequency_student|
        current_student_ids.include?(daily_frequency_student.student_id)
      }

      daily_frequency_students.each(&:mark_for_destruction)
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

  def set_number_of_classes
    @number_of_classes = current_school_calendar.number_of_classes
  end

  def require_teacher
    return if current_teacher.present?

    flash[:alert] = t('errors.daily_frequencies.require_teacher')
    redirect_to root_path
  end

  def student_has_dependence?(student_enrollment, discipline)
    StudentEnrollmentDependence.by_student_enrollment(student_enrollment)
                               .by_discipline(discipline)
                               .any?
  end

  def student_exempted_from_discipline?(student_enrollment, daily_frequency)
    return false if daily_frequency.discipline_id.blank?

    discipline_id = daily_frequency.discipline.id
    frequency_date = daily_frequency.frequency_date
    step_number = daily_frequency.school_calendar.step(frequency_date).try(:to_number)

    student_enrollment.exempted_disciplines
                      .by_discipline(discipline_id)
                      .by_step_number(step_number)
                      .any?
  end
end
