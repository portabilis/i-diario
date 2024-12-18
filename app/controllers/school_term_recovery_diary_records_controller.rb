class SchoolTermRecoveryDiaryRecordsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_classroom
  before_action :require_current_teacher
  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy]

  def index
    step_id = (params[:filter] || []).delete(:by_step_id)

    set_options_by_user

    set_school_term_recovery_diary_records

    if step_id.present?
      @school_term_recovery_diary_records = @school_term_recovery_diary_records.by_step_id(
        current_user_classroom,
        step_id
      )
      params[:filter][:by_step_id] = step_id
    end

    authorize @school_term_recovery_diary_records
  end

  def new
    @school_term_recovery_diary_record = SchoolTermRecoveryDiaryRecord.new.localized
    @school_term_recovery_diary_record.build_recovery_diary_record
    @school_term_recovery_diary_record.recovery_diary_record.unity = current_unity
    @school_term_recovery_diary_record.recovery_diary_record.classroom_id = current_user_classroom.id
    @school_term_recovery_diary_record.recovery_diary_record.discipline_id = current_user_discipline.id
    set_options_by_user
    fetch_disciplines_by_classroom

    current_year_last_step = StepsFetcher.new(current_user_classroom).last_step_by_year

    if current_test_setting.blank? && @admin_or_teacher && current_year_last_step.blank?
      flash[:error] = t('errors.avaliations.require_setting')

      redirect_to(school_term_recovery_diary_records_path)
    end

    return if performed?

    @number_of_decimal_places = current_test_setting&.number_of_decimal_places ||
                                current_test_setting_step(current_year_last_step)&.number_of_decimal_places
  end

  def create
    @school_term_recovery_diary_record = SchoolTermRecoveryDiaryRecord.new.localized
    @school_term_recovery_diary_record.assign_attributes(resource_params.to_h)
    @school_term_recovery_diary_record.step_number = @school_term_recovery_diary_record.step.try(:step_number)
    @school_term_recovery_diary_record.recovery_diary_record.teacher_id = current_teacher_id

    authorize @school_term_recovery_diary_record

    if @school_term_recovery_diary_record.save
      respond_with @school_term_recovery_diary_record, location: school_term_recovery_diary_records_path
    else
      if @admin_or_teacher
        @number_of_decimal_places = current_test_setting.number_of_decimal_places
      else
        fetch_linked_by_teacher
      end
      fetch_disciplines_by_classroom

      render :new
    end
  end

  def edit
    @school_term_recovery_diary_record = SchoolTermRecoveryDiaryRecord.find(params[:id]).localized
    step_number = @school_term_recovery_diary_record.step_number
    step = steps_fetcher.step(step_number)
    @school_term_recovery_diary_record.step_id = step.try(:id)
    set_options_by_user
    fetch_disciplines_by_classroom

    if @school_term_recovery_diary_record.step_id.blank?
      recorded_at = @school_term_recovery_diary_record.recorded_at
      flash[:alert] = t('errors.general.calendar_step_not_found', date: recorded_at)

      return redirect_to school_term_recovery_diary_records_path
    end

    authorize @school_term_recovery_diary_record

    reload_students_list

    students_in_recovery = fetch_students_in_recovery
    mark_students_not_in_recovery_for_destruction(students_in_recovery)
    mark_exempted_disciplines(students_in_recovery)

    @any_student_exempted_from_discipline = any_student_exempted_from_discipline?
    @number_of_decimal_places = current_test_setting&.number_of_decimal_places ||
                                current_test_setting_step(step)&.number_of_decimal_places
  end

  def update
    @school_term_recovery_diary_record = SchoolTermRecoveryDiaryRecord.find(params[:id]).localized
    @school_term_recovery_diary_record.assign_attributes(resource_params.to_h)
    @school_term_recovery_diary_record.recovery_diary_record.teacher_id = current_teacher_id
    @school_term_recovery_diary_record.recovery_diary_record.current_user = current_user

    authorize @school_term_recovery_diary_record

    if @school_term_recovery_diary_record.save
      respond_with @school_term_recovery_diary_record, location: school_term_recovery_diary_records_path
    else
      if @admin_or_teacher
        @number_of_decimal_places = current_test_setting.number_of_decimal_places
      else
        fetch_linked_by_teacher
      end
      reload_students_list
      fetch_disciplines_by_classroom

      render :edit
    end
  end

  def destroy
    @school_term_recovery_diary_record = SchoolTermRecoveryDiaryRecord.find(params[:id])

    @school_term_recovery_diary_record.recovery_diary_record.destroy

    respond_with @school_term_recovery_diary_record, location: school_term_recovery_diary_records_path
  end

  def history
    @school_term_recovery_diary_record = SchoolTermRecoveryDiaryRecord.find(params[:id])

    authorize @school_term_recovery_diary_record

    respond_with @school_term_recovery_diary_record
  end

  def fetch_step
    return if params[:classroom_id].blank?

    classroom = Classroom.find(params[:classroom_id])
    step_numbers = StepsFetcher.new(classroom)&.steps
    steps = step_numbers.map { |step| { id: step.id, description: step.to_s } }

    render json: steps.to_json
  end

  def fetch_number_of_decimal_places
    return if params[:classroom_id].blank?

    classroom = Classroom.find(params[:classroom_id])
    number_of_decimal_places = TestSettingFetcher.current(classroom)

    render json: number_of_decimal_places.to_json
  end

  private

  def resource_params
    params.require(:school_term_recovery_diary_record).permit(
      :step_id,
      :recorded_at,
      recovery_diary_record_attributes: [
        :id,
        :unity_id,
        :classroom_id,
        :discipline_id,
        :recorded_at,
        students_attributes: [
          :id,
          :student_id,
          :score,
          :_destroy
        ]
      ]
    )
  end

  def steps_fetcher
    @steps_fetcher ||= StepsFetcher.new(current_user_classroom)
  end

  def test_setting
    @test_setting ||= TestSettingFetcher.current(current_user_classroom, @school_term_recovery_diary_record.step)
  end

  def decimal_places
    test_setting.number_of_decimal_places
  end
  helper_method :decimal_places

  def fetch_students_in_recovery
    StudentsInRecoveryFetcher.new(
      api_configuration,
      @school_term_recovery_diary_record.recovery_diary_record.classroom_id,
      @school_term_recovery_diary_record.recovery_diary_record.discipline_id,
      @school_term_recovery_diary_record.step_id,
      @school_term_recovery_diary_record.recorded_at
    ).fetch
  end

  def mark_students_not_in_recovery_for_destruction(students_in_recovery)
    students_in_recovery_ids = students_in_recovery.map { |s| s[:student].id }

    @students.each do |student|
      unless students_in_recovery_ids.include?(student.student_id)
        student.mark_for_destruction
      end
    end
  end

  def mark_exempted_disciplines(students_in_recovery)
    students_in_recovery_map = students_in_recovery.index_by { |s| s[:student].id }

    @students.each do |student|
      student.exempted_from_discipline = students_in_recovery_map.dig(
        student.student_id, :exempted_from_discipline
      ) || false
    end
  end

  def any_student_exempted_from_discipline?
    @students.any?(&:exempted_from_discipline)
  end

  def api_configuration
    IeducarApiConfiguration.current
  end

  def fetch_student_enrollment_classrooms
    recovery_diary_record = @school_term_recovery_diary_record.recovery_diary_record
    return unless recovery_diary_record.recorded_at

    @student_enrollment_classroom ||= StudentEnrollmentClassroomsRetriever.call(
      classrooms: recovery_diary_record.classroom,
      disciplines: recovery_diary_record.discipline,
      score_type: StudentEnrollmentScoreTypeFilters::NUMERIC,
      date: recovery_diary_record.recorded_at,
      search_type: :by_date
    )
  end

  def reload_students_list
    recovery_diary_record = @school_term_recovery_diary_record.recovery_diary_record

    test_date = recovery_diary_record.recorded_at

    return unless test_date

    student_enrollment_ids = fetch_student_enrollment_classrooms.map { |sec| sec[:student_enrollment].id }
    @active = ActiveStudentsOnDate.call(student_enrollments: student_enrollment_ids, date: test_date)
    @students = []

    @students = fetch_student_enrollment_classrooms.map do |student|
      note_student = recovery_diary_record.students.find_or_initialize_by(student: student[:student])
      note_student.active = @active.include?(student[:student_enrollment_classroom].id)
      note_student
    end
  end

  def set_options_by_user
    @admin_or_teacher = current_user.current_role_is_admin_or_employee?

    return fetch_linked_by_teacher unless @admin_or_teacher

    @classrooms ||= [current_user_classroom]
    @disciplines ||= [current_user_discipline]
  end

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(
      current_teacher.id,
      current_unity,
      current_school_year
    )
    @disciplines ||= @fetch_linked_by_teacher[:disciplines]
    @classrooms ||= @fetch_linked_by_teacher[:classrooms]
  end

  def set_school_term_recovery_diary_records
    @school_term_recovery_diary_records = if @admin_or_teacher
                                            school_term_recovery_diary_records_for_admin
                                          else
                                            school_term_recovery_diary_records_for_teacher
                                          end

    @school_term_recovery_diary_records = @school_term_recovery_diary_records.ordered.distinct
  end

  def school_term_recovery_diary_records_for_teacher
    base_query
      .joins(recovery_diary_record: :classroom)
      .joins('INNER JOIN teacher_discipline_classrooms tdc ON tdc.classroom_id = classrooms.id AND tdc.discipline_id = recovery_diary_records.discipline_id')
      .where('tdc.teacher_id = ? AND tdc.discarded_at IS NULL', current_teacher.id)
  end

  def school_term_recovery_diary_records_for_admin
    base_query
      .by_classroom_id(@classrooms.pluck(:id))
      .by_discipline_id(@disciplines.pluck(:id))
  end

  def base_query
    apply_scopes(SchoolTermRecoveryDiaryRecord)
      .includes(recovery_diary_record: [:unity, :classroom, :discipline])
  end

  def fetch_disciplines_by_classroom
    return if current_user.current_role_is_admin_or_employee?

    classroom = @school_term_recovery_diary_record.recovery_diary_record.classroom
    @disciplines = @disciplines.by_classroom(classroom).not_descriptor
  end
end
