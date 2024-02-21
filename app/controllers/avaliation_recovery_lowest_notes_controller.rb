class AvaliationRecoveryLowestNotesController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_classroom
  before_action :require_current_teacher
  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy]
  before_action :arithmetic_test_setting

  def index
    step_id = (params[:filter] || []).delete(:by_step_id)
    set_options_by_user

    @lowest_note_recoverys = apply_scopes(AvaliationRecoveryLowestNote)
                                            .includes(
                                              recovery_diary_record: [
                                                :unity,
                                                :classroom,
                                                :discipline
                                              ]
                                            )
                                            .by_classroom_id(@classrooms.map(&:id))
                                            .by_discipline_id(@disciplines.map(&:id))
                                            .ordered

    if step_id.present?
      @lowest_note_recoverys = @lowest_note_recoverys.by_step_id(
        current_user_classroom,
        step_id
      )
      params[:filter][:by_step_id] = step_id
    end

    authorize @lowest_note_recoverys
  end

  def new
    set_options_by_user

    @lowest_note_recovery = AvaliationRecoveryLowestNote.new.localized
    @lowest_note_recovery.build_recovery_diary_record(
      classroom_id: current_user_classroom.id,
      discipline_id: current_user_discipline.id
    )
    @lowest_note_recovery.recovery_diary_record.unity = current_unity
    @students_lowest_note = StudentNotesInStepFetcher.new

    fetch_disciplines_by_classroom

    if current_test_setting.blank?
      flash[:error] = t('errors.avaliations.require_setting')

      redirect_to(avaliation_recovery_lowest_note_path)
    end

    return if performed?

    @number_of_decimal_places = current_test_setting.number_of_decimal_places
  end

  def create
    @lowest_note_recovery = AvaliationRecoveryLowestNote.new.localized
    @lowest_note_recovery.assign_attributes(resource_params.to_h)
    @lowest_note_recovery.step_number = @lowest_note_recovery.step.try(:step_number)
    @lowest_note_recovery.recovery_diary_record.teacher_id = current_teacher_id

    authorize @lowest_note_recovery

    if @lowest_note_recovery.save
      respond_with @lowest_note_recovery, location: avaliation_recovery_lowest_notes_path
    else
      set_options_by_user
      fetch_disciplines_by_classroom

      @number_of_decimal_places = current_test_setting.number_of_decimal_places if current_user.current_role_is_admin_or_employee?

      render :new
    end
  end

  def edit
    set_options_by_user

    @lowest_note_recovery = AvaliationRecoveryLowestNote.find(params[:id]).localized
    step_number = @lowest_note_recovery.step_number
    @lowest_note_recovery.step_id = steps_fetcher.step(step_number).try(:id)
    fetch_disciplines_by_classroom

    if @lowest_note_recovery.step_id.blank?
      recorded_at = @lowest_note_recovery.recorded_at
      flash[:alert] = t('errors.general.calendar_step_not_found', date: recorded_at)

      return redirect_to avaliation_recovery_lowest_notes_path
    end

    authorize @lowest_note_recovery

    fetch_data
  end

  def update
    @lowest_note_recovery = AvaliationRecoveryLowestNote.find(params[:id]).localized
    @lowest_note_recovery.assign_attributes(resource_params.to_h)
    @lowest_note_recovery.recovery_diary_record.teacher_id = current_teacher_id
    @lowest_note_recovery.recovery_diary_record.current_user = current_user

    authorize @lowest_note_recovery

    if @lowest_note_recovery.save
      respond_with @lowest_note_recovery, location: avaliation_recovery_lowest_notes_path
    else
      set_options_by_user
      fetch_disciplines_by_classroom

      @number_of_decimal_places = current_test_setting.number_of_decimal_places if current_user.current_role_is_admin_or_employee?

      render :edit
    end
  end

  def destroy
    @lowest_note_recovery = AvaliationRecoveryLowestNote.find(params[:id])

    @lowest_note_recovery.recovery_diary_record.destroy

    respond_with @lowest_note_recovery, location: avaliation_recovery_lowest_notes_path
  end

  def fetch_step
    return if params[:classroom_id].blank?

    classroom = Classroom.find(params[:classroom_id])
    step_numbers = StepsFetcher.new(classroom)&.steps

    render json: step_numbers.to_json
  end

  def fetch_exam_setting_arithmetic
    return if params[:classroom_id].blank?

    classroom = Classroom.find(params[:classroom_id])
    exam_setting = TestSettingFetcher.current(classroom)

    render json: exam_setting.arithmetic_calculation_type?
  end

  def resource_params
    params.require(:avaliation_recovery_lowest_note).permit(
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

  def fetch_data
    @students_lowest_note = StudentNotesInStepFetcher.new

    reload_students_list

    students = fetch_students
    mark_exempted_disciplines(students)
    add_missing_students(students)

    @any_student_exempted_from_discipline = any_student_exempted_from_discipline?
    @number_of_decimal_places = current_test_setting.number_of_decimal_places
  end

  def steps_fetcher
    @steps_fetcher ||= StepsFetcher.new(current_user_classroom)
  end

  def set_options_by_user
    if current_user.current_role_is_admin_or_employee?
      @classrooms ||= [current_user_classroom]
      @disciplines ||= [current_user_discipline]
    else
      fetch_linked_by_teacher
    end
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

  def test_setting
    @test_setting ||= TestSettingFetcher.current(current_user_classroom, @lowest_note_recovery.step)
  end

  def decimal_places
    test_setting.number_of_decimal_places
  end
  helper_method :decimal_places

  def mark_exempted_disciplines(students_in_recovery)
    @students.each do |student|
      exempted_from_discipline = students_in_recovery.find do |student_in_recovery|
        student_in_recovery.id == student.student_id
      end.try(:exempted_from_discipline)

      student.exempted_from_discipline = exempted_from_discipline
    end
  end

  def add_missing_students(students_in_recovery)
    students_missing = students_in_recovery.select do |student_in_recovery|
      @students.none? do |student|
        student.student.id == student_in_recovery.id
      end
    end

    students_missing.each do |student_missing|
      student = @lowest_note_recovery.recovery_diary_record.students.build(student: student_missing)
      @students << student
    end
  end

  def any_student_exempted_from_discipline?
    @students.any?(&:exempted_from_discipline)
  end

  def api_configuration
    IeducarApiConfiguration.current
  end

  def fetch_students
    recovery_diary_record = @lowest_note_recovery.recovery_diary_record
    return unless recovery_diary_record.recorded_at

    StudentEnrollmentsList.new(
      classroom: recovery_diary_record.classroom,
      discipline: recovery_diary_record.discipline,
      score_type: StudentEnrollmentScoreTypeFilters::NUMERIC,
      date: recovery_diary_record.recorded_at,
      search_type: :by_date
    ).student_enrollments.map(&:student)
  end

  def fetch_students_enrollments
    recovery_diary_record = @lowest_note_recovery.recovery_diary_record
    return unless recovery_diary_record.recorded_at

    StudentEnrollmentsList.new(
      classroom: recovery_diary_record.classroom,
      discipline: recovery_diary_record.discipline,
      score_type: StudentEnrollmentScoreTypeFilters::NUMERIC,
      date: recovery_diary_record.recorded_at,
      search_type: :by_date
    ).student_enrollments
  end

  def reload_students_list
    return unless (student_enrollments = fetch_students_enrollments)

    recovery_diary_record = @lowest_note_recovery.recovery_diary_record

    return unless recovery_diary_record.recorded_at

    @students = []

    student_enrollments.each do |student_enrollment|
      next unless (student = Student.find_by(id: student_enrollment.student_id))

      note_student = recovery_diary_record.students.find_by(student_id: student.id) ||
        recovery_diary_record.students.build(student: student)

      note_student.active = student_active_on_date?(student_enrollment, recovery_diary_record)

      @students << note_student
    end

    @students
  end

  def student_active_on_date?(student_enrollment, recovery_diary_record)
    StudentEnrollment.where(id: student_enrollment)
                     .by_classroom(recovery_diary_record.classroom)
                     .by_date(recovery_diary_record.recorded_at)
                     .any?
  end

  def exists_recovery_on_step
    return if params[:classroom_id].blank? || params[:step_id].blank? || params[:discipline_id].blank?

    classroom = Classroom.find(params[:classroom_id])

    render json: AvaliationRecoveryLowestNote.by_step_id(classroom, params[:step_id])
                                             .by_classroom_id(classroom.id)
                                             .by_discipline_id(params[:discipline_id])
                                             .exists?
  end

  def recorded_at_in_selected_step
    return render json: nil if params[:step_id].blank? || params[:recorded_at].blank? || params[:classroom_id].blank?

    classroom = Classroom.find(params[:classroom_id])
    steps_fetcher = StepsFetcher.new(classroom)

    render json: steps_fetcher.step_belongs_to_date?(params[:step_id], params[:recorded_at])
  end

  def arithmetic_test_setting
    return unless current_user.current_role_is_admin_or_employee?

    if current_test_setting.blank?
      flash[:error] = t('errors.avaliations.require_setting')

      redirect_to root_path
    end

    return if current_test_setting.arithmetic_calculation_type?

    flash[:alert] = t('activerecord.errors.models.avaliation_recovery_lowest_note.test_setting_without_arithmetic_calculation_type')

    redirect_to root_path
  end

  def fetch_disciplines_by_classroom
    return if current_user.current_role_is_admin_or_employee?

    @disciplines = @disciplines.by_classroom(
      @lowest_note_recovery.recovery_diary_record.classroom
    ).not_descriptor
  end
end
