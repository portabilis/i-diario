class DailyFrequenciesInBatchsController < ApplicationController
  before_action :require_current_classroom
  before_action :require_teacher
  before_action :require_allocation_on_lessons_board
  before_action :set_number_of_classes, only: [:new, :form, :create, :create_or_update_multiple]
  before_action :authorize_daily_frequency, only: [:new, :create, :create_or_update_multiple]
  before_action :require_allow_to_modify_prev_years, only: [:create, :destroy_multiple]
  before_action :require_valid_daily_frequency_classroom

  def new
    classroom_id = teacher_allocated.blank? ? nil : current_user_classroom.id
    discipline_id = teacher_allocated.blank? ? nil : current_user_discipline.id

    @frequency_in_batch_form = FrequencyInBatchForm.new(
      classroom_id: classroom_id,
      discipline_id: discipline_id
    )

    @frequency_type = current_frequency_type(current_user_classroom)

    set_options_by_user
  end

  def form
    create
  end

  def create
    start_date = params[:frequency_in_batch_form][:start_date].to_date
    end_date = params[:frequency_in_batch_form][:end_date].to_date
    classroom_id = params[:frequency_in_batch_form][:classroom_id]
    grade_id = ClassroomsGrade.find_by(classroom_id: classroom_id).grade_id

    if  invalid_dates?(start_date, end_date, classroom_id, grade_id)
      redirect_to(new_daily_frequencies_in_batch_path) and return
    end

    @dates = [*start_date..end_date]
    @classroom = Classroom.includes(:unity).find(params[:frequency_in_batch_form][:classroom_id])
    @discipline = Discipline.find(params[:frequency_in_batch_form][:discipline_id]) if params[:frequency_in_batch_form][:discipline_id].present?

    return unless view_data

    render :create_or_update_multiple
  end

  def create_or_update_multiple
    daily_frequency_attributes = daily_frequency_in_batchs_params
    daily_frequencies_attributes = daily_frequencies_in_batch_params
    receive_email_confirmation = ActiveRecord::Type::Boolean.new.cast(
      daily_frequency_attributes[:frequency_in_batch_form][:receive_email_confirmation]
    )
    dates = []

    ActiveRecord::Base.transaction do
      daily_frequencies_attributes[:daily_frequencies].each_value do |daily_frequency_students_params|
        daily_frequency_data = daily_frequency_attributes
        daily_frequency_data[:frequency_date] = daily_frequency_students_params[:date]
        daily_frequency_data[:class_number] = daily_frequency_students_params[:class_number]

        if daily_frequency_attributes[:frequency_type] == FrequencyTypes::GENERAL
          daily_frequency_data[:class_number] = nil
          daily_frequency_data[:discipline_id] = nil
        end

        daily_frequency = find_or_initialize_daily_frequency_by(daily_frequency_data[:frequency_date],
                                                                daily_frequency_data[:class_number],
                                                                daily_frequency_data[:unity_id],
                                                                daily_frequency_data[:classroom_id],
                                                                daily_frequency_data[:discipline_id],
                                                                daily_frequency_data[:period])

        daily_frequency_students_params[:students_attributes].each_value do |student_attributes|
          away = 0
          daily_frequency_student = daily_frequency.build_or_find_by_student(student_attributes[:student_id])

          if student_attributes[:absence_justification_student_id].to_i.eql?(-1)
            params = {
              student_ids: [student_attributes[:student_id]],
              absence_date: daily_frequency_data[:frequency_date],
              justification: nil,
              absence_date_end: daily_frequency_data[:frequency_date],
              unity_id: daily_frequency_data[:unity_id],
              classroom_id: daily_frequency_data[:classroom_id],
              class_number: daily_frequency_data[:class_number],
            }

            absence_justification = AbsenceJustification.new(params)
            absence_justification.teacher = current_teacher
            absence_justification.user = current_user
            absence_justification.school_calendar = current_school_calendar
            absence_justification.period = daily_frequency_data[:period]

            absence_justification.save

            student_attributes[:absence_justification_student_id] =
              absence_justification.absence_justifications_students.first.id
          end

          daily_frequency_student.present = student_attributes[:present].blank? ? away : student_attributes[:present]
          daily_frequency_student.type_of_teaching = student_attributes[:type_of_teaching]
          daily_frequency_student.active = student_attributes[:active]
          daily_frequency_student.absence_justification_student_id = student_attributes[:absence_justification_student_id]

          daily_frequency.save!
          daily_frequency_student.save!
        end

        if daily_frequency.save!
          UniqueDailyFrequencyStudentsCreator.call_worker(
            current_entity.id,
            daily_frequency.classroom_id,
            daily_frequency.frequency_date,
            current_teacher_id
          )

          dates << daily_frequency.frequency_date.to_date.strftime('%d/%m/%Y')
        end

      end
    end

    if receive_email_confirmation
      ReceiptMailer.delay.notify_daily_frequency_in_batch_success(
        current_user.first_name,
        current_user.email,
        "#{request.base_url}#{create_or_update_multiple_daily_frequencies_in_batchs_path}",
        dates,
        Classroom.find(daily_frequency_attributes[:classroom_id].to_i).description,
        Unity.find(daily_frequency_attributes[:unity_id].to_i).name
      )
    end

    flash[:success] = t('.daily_frequency_success')

    @dates = [*params[:start_date].to_date..params[:end_date].to_date]
    @classroom = Classroom.includes(:unity).find(daily_frequency_attributes[:classroom_id])

    if daily_frequency_attributes[:discipline_id].present?
      @discipline = Discipline.find(daily_frequency_attributes[:discipline_id])
    end

    view_data

    render :create_or_update_multiple
  rescue ActiveRecord::RecordInvalid => e
      flash[:error] = e.message
      redirect_to new_daily_frequencies_in_batch_path
  end

  def destroy_multiple
    @daily_frequencies = DailyFrequency.where(id: params[:daily_frequencies_ids])

    if @daily_frequencies.any?
      @daily_frequencies.each(&:destroy)

      flash[:success] = t('.success')

      redirect_to new_daily_frequencies_in_batch_path
    else
      flash[:alert] = t('.alert')

      redirect_to new_daily_frequencies_in_batch_path
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

  def fetch_frequency_type
    return if params[:classroom_id].blank?

    classroom = Classroom.find(params[:classroom_id])

    render json: current_frequency_type(classroom)
  end

  def fetch_teacher_allocated
    return if params[:classroom_id].blank? || params[:discipline_id].blank?

    @classroom = Classroom.find(params[:classroom_id])
    @discipline = params[:discipline_id]

    render json: teacher_allocated
  end

  private

  def authorize_daily_frequency
    @daily_frequency = DailyFrequency.new.localized

    authorize @daily_frequency
  end

  def view_data
    @period = current_teacher_period == Periods::FULL.to_i ? @classroom.period : current_teacher_period
    @general_configuration = GeneralConfiguration.current
    @frequency_type = current_frequency_type(@classroom)
    params['dates'] = allocation_dates(@dates)
    @frequency_form = FrequencyInBatchForm.new
    @absence_justification = AbsenceJustification.new
    @absence_justification.school_calendar = current_school_calendar
    @students = []
    @students_list = []

    student_enrollments_ids = []
    student_ids = []
    dates = []
    params['dates'].each { |date| dates << date['date'] }

    if dates.empty?
      flash.now[:warning] = t('daily_frequencies_in_batchs.create_or_update_multiple.no_school_day')

      render :new

      return false
    end

    enrollment_classrooms = student_enrollment_classrooms

    enrollment_classrooms.each do |student_enrollment|
      student_enrollments_ids << student_enrollment[:student_enrollment].id
      student = student_enrollment[:student]
      student_ids << student.id
      type_of_teaching = student_enrollment[:student_enrollment_classroom].type_of_teaching
      left_at = student_enrollment[:student_enrollment_classroom].left_at
      joined_at = student_enrollment[:student_enrollment_classroom].joined_at

      next if student.blank?

      @students_list << student
      @students << {
        student: student,
        type_of_teaching: type_of_teaching,
        left_at: left_at,
        joined_at: joined_at
      }
    end

    if @students.blank?
      flash.now[:warning] = t('daily_frequencies_in_batchs.create_or_update_multiple.warning_no_students')

      render :new

      return false
    end

    dependences = student_has_dependence(student_enrollments_ids, dates)
    inactives_on_date = students_inactive_on_range(enrollment_classrooms.map{|i|
                                                                          i[:student_enrollment_classroom]
                                                                        }, dates)
    exempteds_from_discipline = student_exempted_from_discipline_in_range(student_enrollments_ids, dates)
    active_searchs = ActiveSearch.new.in_active_search_in_range(student_enrollments_ids, dates)

    @absence_justifications = AbsenceJustifiedOnDate.call(
      students: student_ids,
      date: dates.first,
      end_date: dates.last,
      classroom: current_user_classroom.id,
      period: @period
    )

    @additional_data = additional_data(dates, student_ids, dependences,
                                       inactives_on_date, exempteds_from_discipline, active_searchs)
  end

  def additional_data(dates, student_ids, dependences, inactives_on_date, exempteds_from_discipline,
                      active_searchs)
    additional_data = []
    dates.each do |date|
      student_ids.each do |student_id|
        if active_searchs.any?
          active_searchs.each do |active_search|
            next if active_search[:date] != date || !active_search[:student_ids].include?(student_id)

            additional_class = 'in-active-search'
            tooltip = t('daily_frequencies_in_batchs.create_or_update_multiple.in_active_search_tooltip')
            additional_data << { date: active_search[:date], student_id: student_id,
                                 additional_class: additional_class, tooltip:  tooltip }
          end
        end
        if dependences.any?
          dependences.each do |dependence|
            next if dependence[:date] != date || !dependence[:student_ids].include?(student_id)

            tooltip = t('daily_frequencies_in_batchs.create_or_update_multiple.dependence_students_tooltip')
            additional_data << { date: dependence[:date], student_id: student_id,
                                 additional_class: '', tooltip:  tooltip }
          end
        end
        if exempteds_from_discipline.any?
          exempteds_from_discipline.each do |exempted_from_discipline|
            next if exempted_from_discipline[:date] != date || !exempted_from_discipline[:student_ids].include?(student_id)

            additional_class = 'exempted'
            tooltip = t('daily_frequencies_in_batchs.create_or_update_multiple.exempted_students_from_discipline_tooltip')
            additional_data << { date: exempted_from_discipline[:date], student_id: student_id,
                                 additional_class: additional_class, tooltip:  tooltip }
          end
        end
        if inactives_on_date.any?
          inactives_on_date.each do |inactive_on_date|
            next if inactive_on_date[:date] != date || !inactive_on_date[:student_ids].include?(student_id)

            additional_class = 'inactive'
            tooltip = t('daily_frequencies_in_batchs.create_or_update_multiple.inactive_students_tooltip')
            additional_data << { date: inactive_on_date[:date], student_id: student_id,
                                 additional_class: additional_class, tooltip:  tooltip }
          end
        end
      end
    end
    additional_data
  end

  def allocation_dates(dates)
    allocation_dates = []
    dates.each do |date|
      lesson_numbers = []
      if @frequency_type == FrequencyTypes::GENERAL
        allocations =  LessonsBoardLessonWeekday.includes(:lessons_board_lesson)
                                                .by_classroom(@classroom.id)
                                                .by_teacher(current_teacher_id)
                                                .by_weekday(date.strftime("%A").downcase)
                                                .order('lessons_board_lessons.lesson_number')
      else
        allocations =  LessonsBoardLessonWeekday.includes(:lessons_board_lesson)
                                                .by_classroom(@classroom.id)
                                                .by_teacher(current_teacher_id)
                                                .by_discipline(@discipline.id)
                                                .by_weekday(date.strftime("%A").downcase)
                                                .order('lessons_board_lessons.lesson_number')
      end

      allocations.by_period(@period) if @period.present?

      if current_user.current_role_is_admin_or_employee?
        school_calendar = current_school_calendar
      else
        school_calendar = CurrentSchoolCalendarFetcher.new(current_unity, @classroom, current_school_year).fetch
      end
      grade_id = @classroom.classrooms_grades.first.grade_id
      valid_day = SchoolDayChecker.new(school_calendar, date, grade_id, @classroom.id, nil).day_allows_entry?

      next if allocations.empty? || !valid_day

      if @frequency_type == FrequencyTypes::BY_DISCIPLINE
        allocations.each { |allocattion| lesson_numbers << allocattion.lessons_board_lesson.lesson_number.to_i }
        allocation_dates << build_hash(date, lesson_numbers.sort.uniq)
      else
        allocation_dates << build_hash(date, nil)
      end
    end

    allocation_dates.first(15)
  end

  def find_or_initialize_daily_frequency_by(date, lesson_number, unity_id, classroom_id, discipline_id, period)
    daily_frequency = DailyFrequency.find_or_initialize_by(unity_id: unity_id,
                                                           classroom_id: classroom_id,
                                                           frequency_date: date,
                                                           discipline_id: discipline_id,
                                                           class_number: lesson_number,
                                                           period: period
    ).tap do |daily_frequency_record|
      daily_frequency_record.school_calendar_id = current_school_calendar.id
      daily_frequency_record.owner_teacher_id = daily_frequency_record.teacher_id = current_teacher_id
      daily_frequency_record.origin = OriginTypes::WEB
    end

    daily_frequency
  end

  def build_hash(date, lesson_numbers)
    return if date.blank?

    daily_frequencies = []
    if lesson_numbers.nil?
      daily_frequencies << find_or_initialize_daily_frequency_by(date, nil, @classroom.unity.id, @classroom.id,
nil, @period)
    else
      lesson_numbers.each do |lesson_number|
        daily_frequencies << find_or_initialize_daily_frequency_by(date, lesson_number,
                                                                   @classroom.unity.id, @classroom.id,
                                                                   @discipline.id, @period)
      end
    end

    {
      date: date,
      lesson_numbers: lesson_numbers,
      daily_frequencies: daily_frequencies
    }
  end

  def daily_frequency_in_batchs_params
    params.permit(
      :unity_id,
      :classroom_id,
      :discipline_id,
      :frequency_type,
      :period,
      frequency_in_batch_form: [
        :receive_email_confirmation
      ]
    )
  end

  def daily_frequencies_in_batch_params
    params.require(:daily_frequency).permit(
      daily_frequencies: [
        :date,
        :class_number,
        students_attributes: [
          :id, :daily_frequency_id, :student_id, :present, :active, :dependence, :type_of_teaching, :absence_justification_student_id
        ]
      ]
    )
  end

  def current_frequency_type(classroom)
    absence_type_definer = FrequencyTypeDefiner.new(
      classroom,
      current_teacher,
      year: classroom.year
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

  def current_teacher_period
    TeacherPeriodFetcher.new(
      current_teacher.id,
      @classroom.id,
      @discipline.id
    ).teacher_period
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

  def student_enrollment_classrooms
    StudentEnrollmentClassroomsRetriever.call(
      classrooms: @classroom,
      disciplines: @discipline,
      start_at: params[:start_date] || params[:frequency_in_batch_form][:start_date],
      end_at: params[:end_date] || params[:frequency_in_batch_form][:end_date],
      show_inactive_outside_step: false,
      search_type: :by_date_range,
      period: @period,
      remove_duplicate_student: false
    )
  end

  def students_inactive_on_range(enrollment_classrooms, dates)
    inactives = []

    dates.each do |date|
      active_enrollments_classroom_ids = enrollment_classrooms.select do |enrollment|
        enrollment.joined_at.to_date <= date && (enrollment.left_at.blank? || enrollment.left_at.to_date > date)
      end.pluck(:id)

      next if active_enrollments_classroom_ids.sort == enrollment_classrooms.pluck(:id).sort

      inactives_enrollments_classroom_ids = enrollment_classrooms.pluck(:id) - active_enrollments_classroom_ids

      inactives_students_ids = Student.joins(student_enrollments: :student_enrollment_classrooms)
                                      .where(student_enrollment_classrooms: {
                                               id: inactives_enrollments_classroom_ids
                                             })
                                      .pluck(:id)

      inactives << { date: date, student_ids: inactives_students_ids}

    end

    inactives
  end

  def set_number_of_classes
    @number_of_classes = current_school_calendar.number_of_classes
  end

  def require_teacher
    return if current_teacher.present?

    flash[:alert] = t('errors.daily_frequencies.require_teacher')
    redirect_to root_path
  end

  def student_has_dependence(student_enrollments, frequency_dates)
    students_dependences = StudentEnrollmentDependence.by_student_enrollment(student_enrollments)
                                                      .by_discipline(@discipline.id)
                                                      .includes(student_enrollment: [:student])
                                                      .pluck('students.id')

    return students_dependences if students_dependences&.empty?

    students_with_dependences = []

    frequency_dates.each do |date|
      students_with_dependences << { date: date, student_ids: students_dependences }
    end

    students_with_dependences
  end

  def student_exempted_from_discipline_in_range(student_enrollments_ids, frequency_dates)
    return if @discipline.blank?

    exempteds = []
    steps = []

    frequency_dates.each do |date|
      steps << current_school_calendar.step(date.to_date).try(:to_number)
    end

    steps.uniq.compact.each do |step_number|
      students_exempteds = StudentEnrollmentExemptedDiscipline.where(student_enrollment_id: student_enrollments_ids)
                                                              .by_discipline(@discipline.id)
                                                              .by_step_number(step_number)
                                                              .includes(student_enrollment: [:student])
                                                              .pluck('students.id')
      next if students_exempteds&.empty?

      exempteds << { step_number: step_number, student_ids: students_exempteds }
    end

    exempteds.compact
  end

  def require_valid_daily_frequency_classroom
    return unless params[:frequency_in_batch_form]
    return unless params[:frequency_in_batch_form][:classroom_id]
    return if current_user.current_classroom_id == params[:frequency_in_batch_form][:classroom_id].to_i

    redirect_to new_daily_frequency_path
  end

  def require_allocation_on_lessons_board
    return if teacher_allocated

    @admin_or_teacher = current_user.current_role_is_admin_or_employee?

    flash[:alert] = t('errors.daily_frequencies.require_lessons_board')
    redirect_to root_path if @admin_or_teacher
  end

  def set_options_by_user
    return fetch_linked_by_teacher unless @admin_or_teacher

    @classrooms ||= [current_user_classroom]
    @disciplines ||= [current_user_discipline]
  end

  def teacher_allocated
    @classroom ||= current_user_classroom
    @discipline ||= current_user_discipline

    frequency_type = current_frequency_type(@classroom)

    if frequency_type == FrequencyTypes::BY_DISCIPLINE
      LessonsBoard.by_teacher(current_teacher)
                  .by_classroom(@classroom)
                  .by_discipline(@discipline)
                  .exists?
    else
      LessonsBoard.by_teacher(current_teacher)
                  .by_classroom(@classroom)
                  .exists?
    end
  end

  def invalid_dates?(start_date, end_date, classroom_id, grade_id)
    if start_date.nil? || end_date.nil?
      flash[:error] = t('daily_frequencies_in_batchs.create_or_update_multiple.blank_dates')
      return true
    end

    unless SchoolDayChecker.new(current_school_calendar, start_date, grade_id, classroom_id, nil).school_day?
      flash[:error] = t('daily_frequencies_in_batchs.create_or_update_multiple.initial_date_no_school_day')
      return true
    end
    unless SchoolDayChecker.new(current_school_calendar, end_date, grade_id, classroom_id, nil).school_day?
      flash[:error] = t('daily_frequencies_in_batchs.create_or_update_multiple.final_date_no_school_day')
      return true
    end

    if start_date > Time.zone.today || end_date > Time.zone.today
      flash[:error] = t('daily_frequencies_in_batchs.create_or_update_multiple.future_date')
      return true
    end

    if start_date > end_date
      flash[:error] = t('daily_frequencies_in_batchs.create_or_update_multiple.start_date_greater_end_date')
      true
    end
  end

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(current_teacher.id, current_unity,
current_school_year)
    @disciplines = []
    @classrooms = []

    # Remove turmas que não estão no quadro de aulas
    @fetch_linked_by_teacher[:classrooms].each do |classroom|
      lesson_board = LessonsBoard.by_teacher(current_teacher)
                                 .by_classroom(classroom)
                                 .exists?
      @classrooms << classroom if lesson_board
    end

    # Remove disciplinas que não estão no quadro de aulas
    @fetch_linked_by_teacher[:disciplines].each do |discipline|
      lesson_board = LessonsBoard.by_teacher(current_teacher)
                                 .by_classroom(@classrooms)
                                 .by_discipline(discipline)
                                 .exists?
      @disciplines << discipline if lesson_board
    end
    @disciplines.uniq
  end
end
