class DailyFrequenciesController < ApplicationController
  before_action :require_current_classroom
  before_action :require_teacher
  before_action :set_number_of_classes, only: [:new, :form, :create, :edit_multiple]
  before_action :require_allow_to_modify_prev_years, only: [:create, :destroy_multiple]
  before_action :require_valid_daily_frequency_classroom

  def new
    set_options_by_user

    @daily_frequency = DailyFrequency.new.localized
    @daily_frequency.unity = current_unity
    @daily_frequency.classroom = current_user_classroom
    @daily_frequency.discipline = current_user_discipline
    @daily_frequency.frequency_date = Date.current
    @period = @admin_or_teacher ? current_teacher_period : set_options_by_classroom
    @class_numbers = []

    unless current_user.current_role_is_admin_or_employee?
      classroom = @daily_frequency.classroom
      @disciplines = @disciplines.by_classroom(classroom).not_descriptor
    end

    authorize @daily_frequency
  end

  def form
    redirect_to edit_multiple_daily_frequencies_path(
      daily_frequency: {
        unity_id: params[:unity_id],
        classroom_id: params[:classroom_id],
        frequency_date: params[:frequency_date],
        discipline_id: params[:discipline_id],
        period: params[:period]
      },
      class_numbers: params[:class_numbers].split(',').sort
    )
  end

  def create
    set_options_by_user

    @daily_frequency = DailyFrequency.new(daily_frequency_params)
    @daily_frequency.school_calendar = current_school_calendar
    @daily_frequency.teacher_id = current_teacher_id
    @class_numbers = params[:class_numbers].split(',').sort
    @daily_frequency.class_number = @class_numbers.first
    @discipline = params[:daily_frequency][:discipline_id]

    @period = @admin_or_teacher ? params[:daily_frequency][:period] : set_options_by_classroom

    if @daily_frequency.valid?
      @frequency_type = current_frequency_type(@daily_frequency)

      return if @frequency_type == FrequencyTypes::BY_DISCIPLINE && !(validate_class_numbers && validate_discipline)

      redirect_to edit_multiple_daily_frequencies_path(
        daily_frequency: daily_frequency_params,
        class_numbers: @class_numbers
      )
    else
      render :new
    end
  end

  def edit_multiple
    set_options_by_user
    @daily_frequencies = find_or_initialize_daily_frequencies(params[:class_numbers])
      .sort { |a, b| a.class_number <=> b.class_number }
    @daily_frequency = @daily_frequencies.first
    @period = @admin_or_teacher ? current_teacher_period : set_options_by_classroom

    @period = @period != Periods::FULL.to_i ? @period : nil

    @general_configuration = GeneralConfiguration.current

    authorize @daily_frequency

    @students = []
    @students_list = []
    @any_exempted_from_discipline = false
    @any_inactive_student = false
    @any_in_active_search = false
    @dependence_students = false
    @absence_justification = AbsenceJustification.new
    @absence_justification.school_calendar = current_school_calendar
    enrollment_classrooms = fetch_enrollment_classrooms

    student_enrollment_ids = enrollment_classrooms.map { |student_enrollment|
      student_enrollment[:student_enrollment_id]
    }

    student_ids = enrollment_classrooms.map { |student_enrollment|
      student_enrollment[:student].id
    }

    step = @daily_frequency.school_calendar.step(@daily_frequency.frequency_date).try(:to_number)
    discipline = @daily_frequency.discipline
    frequency_date = @daily_frequency.frequency_date

    dependencies = StudentsInDependency.call(student_enrollments: student_enrollment_ids, disciplines: discipline)
    exempt = StudentsExemptFromDiscipline.call(student_enrollments: student_enrollment_ids, discipline: discipline, step: step)
    active = ActiveStudentsOnDate.call(student_enrollments: student_enrollment_ids, date: frequency_date)
    active_search = in_active_searches(student_enrollment_ids, @daily_frequency.frequency_date)
    absence_justifications = AbsenceJustifiedOnDate.call(
      students: student_ids,
      date: frequency_date,
      end_date: frequency_date,
      classroom: @daily_frequency.classroom_id,
      period: @period
    )

    enrollment_classrooms.each do |enrollment_classroom|
      student = enrollment_classroom[:student]
      student_enrollment_id = enrollment_classroom[:student_enrollment_id]
      activated_student = active.include?(enrollment_classroom[:student_enrollment_classroom_id])
      has_dependence = dependencies[student_enrollment_id] ? true : false
      has_exempted = exempt[student_enrollment_id] ? true : false
      absence_justification = absence_justifications[student.id] || {}
      in_active_search = active_search[@daily_frequency.frequency_date]&.include?(student_enrollment_id)
      sequence = enrollment_classroom[:sequence] if show_inactive_enrollments

      @any_exempted_from_discipline ||= has_exempted
      @any_in_active_search ||= in_active_search
      @dependence_students ||= has_dependence
      @any_inactive_student ||= !activated_student

      next unless activated_student || show_inactive_enrollments

      @students_list << student
      @students << {
        student: student,
        dependence: has_dependence,
        active: activated_student,
        exempted_from_discipline: has_exempted,
        in_active_search: in_active_search,
        absence_justification: absence_justification,
        sequence: sequence
      }
    end

    all_inactive = @students.all? { |element| element[:active] == false }

    if @students.blank? || all_inactive
      flash.now[:warning] = t('.warning_no_students')

      render :new

      return
    end

    build_daily_frequency_students
    mark_for_destruction_not_existing_students

    @students = @students.sort_by { |student| student[:sequence] } if show_inactive_enrollments
  end

  def create_or_update_multiple
    begin
      daily_frequency_record = nil
      daily_frequency_attributes = daily_frequency_params
      daily_frequencies_attributes = daily_frequencies_params
      receive_email_confirmation = ActiveRecord::Type::Boolean.new.cast(
        params[:daily_frequency][:receive_email_confirmation]
      )

      edit_multiple_daily_frequencies_path = edit_multiple_daily_frequencies_path(
        daily_frequency: daily_frequency_attributes.slice(
          :classroom_id,
          :discipline_id,
          :frequency_date,
          :period,
          :unity_id
        ),
        class_numbers: class_numbers_from_params
      )

      ActiveRecord::Base.transaction do
        daily_frequencies_attributes.each_value do |daily_frequency_students_params|
          daily_frequency_attribute_normalizer = DailyFrequencyAttributesNormalizer.new(
            daily_frequency_students_params,
            daily_frequency_attributes
          )
          daily_frequency_attribute_normalizer.normalize_daily_frequency!

          daily_frequency_record = find_or_initialize_daily_frequency_by(daily_frequency_attributes)
          daily_frequency_attribute_normalizer.normalize_daily_frequency_students!(
            daily_frequency_record,
            daily_frequency_students_params
          )

          daily_frequency_students_params[:students_attributes].each_value do |daily_frequency_student|
            next unless daily_frequency_student[:absence_justification_student_id].to_i.eql?(-1)

            params = {
              student_ids: [daily_frequency_student[:student_id]],
              absence_date: daily_frequency_attributes[:frequency_date],
              justification: nil,
              absence_date_end: daily_frequency_attributes[:frequency_date],
              unity_id: daily_frequency_attributes[:unity_id],
              classroom_id: daily_frequency_attributes[:classroom_id],
              class_number: daily_frequency_students_params[:class_number]
            }

            absence_justification = AbsenceJustification.new(params)
            absence_justification.teacher = current_teacher
            absence_justification.user = current_user
            absence_justification.school_calendar = current_school_calendar
            absence_justification.period = daily_frequency_attributes[:period]

            absence_justification.save

            daily_frequency_student[:absence_justification_student_id] = absence_justification.absence_justifications_students.first.id
          end
          daily_frequency_record.assign_attributes(daily_frequency_students_params)

          daily_frequency_record.save!
        end
      end
    rescue ActiveRecord::RecordNotUnique
      retry
    rescue ActiveRecord::RecordInvalid => e
      flash[:error] = e.message
      return redirect_to new_daily_frequency_path
    end

    flash[:success] = t('.daily_frequency_success')

    UniqueDailyFrequencyStudentsCreator.call_worker(
      current_entity.id,
      daily_frequency_record.classroom_id,
      daily_frequency_record.frequency_date,
      current_teacher_id
    )

    if receive_email_confirmation
      ReceiptMailer.delay.notify_daily_frequency_success(
        current_user.first_name,
        current_user.email,
        "#{request.base_url}#{edit_multiple_daily_frequencies_path}",
        daily_frequency_attributes[:frequency_date].to_date.strftime('%d/%m/%Y'),
        daily_frequency_record.classroom.description,
        daily_frequency_record.unity.name
      )
    end

    redirect_to edit_multiple_daily_frequencies_path
  end

  def destroy_multiple
    @daily_frequencies = DailyFrequency.where(id: params[:daily_frequencies_ids])

    if @daily_frequencies.any?
      daily_frequency = @daily_frequencies.first
      classroom_id = daily_frequency.classroom_id
      frequency_date = daily_frequency.frequency_date

      authorize daily_frequency

      @daily_frequencies.each(&:destroy)

      UniqueDailyFrequencyStudentsCreator.call_worker(
        current_entity.id,
        classroom_id,
        frequency_date,
        current_teacher_id
      )

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
          [:id, :daily_frequency_id, :student_id, :present, :dependence, :active, :type_of_teaching, :absence_justification_student_id]
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
    return find_or_initialize_discipline_frequencies(class_numbers) if class_numbers?(class_numbers)

    find_or_initialize_global_frequencies
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
      daily_frequency_record.owner_teacher_id = daily_frequency_record.teacher_id = current_teacher_id
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

  def current_teacher_period_by_classroom(classroom, discipline)
    TeacherPeriodFetcher.new(
      current_teacher.id,
      classroom,
      discipline
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

  def fetch_enrollment_classrooms
    StudentEnrollmentsList.new(
      classroom: @daily_frequency.classroom,
      grade: discipline_classroom_grade_ids,
      discipline: @daily_frequency.discipline,
      date: @daily_frequency.frequency_date,
      search_type: :by_date,
      period: @period
    ).student_enrollment_classrooms
  end

  def set_number_of_classes
    @number_of_classes = current_school_calendar.number_of_classes
  end

  def require_teacher
    return if current_teacher.present?

    flash[:alert] = t('errors.daily_frequencies.require_teacher')
    redirect_to root_path
  end

  def in_active_searches(student_enrollment_ids, frequency_date)
    @in_active_searches ||= ActiveSearch.new.enrollments_in_active_search?(student_enrollment_ids, frequency_date)
  end

  def class_numbers_from_params
    daily_frequencies_params.map { |daily_frequency_students_params|
      daily_frequency_students_params.second[:class_number].presence
    }.compact
  end

  def class_numbers?(class_numbers)
    return false if class_numbers.blank?

    class_numbers = (class_numbers - [0, '0', '', nil, '[]'])
    class_numbers.present?
  end

  def require_valid_daily_frequency_classroom
    return unless current_user.current_role_is_admin_or_employee?
    return unless params[:daily_frequency]
    return unless params[:daily_frequency][:classroom_id]
    return if current_user.current_classroom_id == params[:daily_frequency][:classroom_id].to_i

    redirect_to new_daily_frequency_path
  end

  def discipline_classroom_grade_ids
    classroom_grade_ids = ClassroomsGrade.by_classroom_id(@daily_frequency.classroom.id).pluck(:grade_id)
    school_calendar = StepsFetcher.new(@daily_frequency.classroom).school_calendar

    if @frequency_type == FrequencyTypes::BY_DISCIPLINE
      SchoolCalendarDisciplineGrade.where(
        grade_id: classroom_grade_ids,
        school_calendar_id: school_calendar.id,
        discipline_id: @daily_frequency.discipline.id
      ).pluck(:grade_id)
    else
      SchoolCalendarDisciplineGrade.where(
        grade_id: classroom_grade_ids,
        school_calendar_id: school_calendar.id
      ).pluck(:grade_id)
    end
  end

  def show_inactive_enrollments
    @show_inactive_enrollments ||= GeneralConfiguration.first.show_inactive_enrollments
  end

  def set_options_by_classroom
    classroom = @daily_frequency.classroom
    discipline = @daily_frequency.discipline

    @period = current_teacher_period_by_classroom(classroom, discipline)
    @daily_frequency.period = @period
  end

  def set_options_by_user
    @admin_or_teacher = current_user.current_role_is_admin_or_employee?

    if @admin_or_teacher
      @classrooms ||= [current_user_classroom]
      @disciplines ||= [current_user_discipline]
      @period = current_teacher_period
    else
      fetch_linked_by_teacher
    end
  end

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(current_teacher.id, current_unity, current_school_year)
    @classrooms ||= @fetch_linked_by_teacher[:classrooms]
    @disciplines ||= @fetch_linked_by_teacher[:disciplines]
  end
end
