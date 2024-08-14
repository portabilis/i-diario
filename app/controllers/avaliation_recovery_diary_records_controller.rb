class AvaliationRecoveryDiaryRecordsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_classroom
  before_action :require_current_teacher
  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy]

  def index
    set_options_by_user
    fetch_avaliation_recovery_diary_records_by_user

    authorize @avaliation_recovery_diary_records

    @school_calendar_steps = steps_fetcher.steps
  end

  def new
    set_options_by_user

    @avaliation_recovery_diary_record = AvaliationRecoveryDiaryRecord.new.localized
    @avaliation_recovery_diary_record.build_recovery_diary_record
    @avaliation_recovery_diary_record.recovery_diary_record.unity = current_unity
    @avaliation_recovery_diary_record.recovery_diary_record.classroom = current_user_classroom
    @avaliation_recovery_diary_record.recovery_diary_record.discipline = current_user_discipline

    @unities = fetch_unities
    @school_calendar_steps = steps_fetcher.steps

    fetch_disciplines_by_classroom

    if current_test_setting.blank?
      flash[:error] = t('errors.avaliations.require_setting')

      redirect_to(avaliation_recovery_diary_records_path)
    end

    return if performed?

    @number_of_decimal_places = current_test_setting.number_of_decimal_places
  end

  def create
    @avaliation_recovery_diary_record = AvaliationRecoveryDiaryRecord.new.localized
    @avaliation_recovery_diary_record.assign_attributes(resource_params.to_h)
    @avaliation_recovery_diary_record.recovery_diary_record.teacher_id = current_teacher_id

    authorize @avaliation_recovery_diary_record

    if @avaliation_recovery_diary_record.save
      respond_with @avaliation_recovery_diary_record, location: avaliation_recovery_diary_records_path
    else
      set_options_by_user
      fetch_disciplines_by_classroom

      @number_of_decimal_places = current_test_setting.number_of_decimal_places
      reload_students_list if daily_note_students.present?

      render :new
    end
  end

  def edit
    set_options_by_user

    @avaliation_recovery_diary_record = AvaliationRecoveryDiaryRecord.find(params[:id]).localized

    fetch_disciplines_by_classroom

    authorize @avaliation_recovery_diary_record

    add_missing_students
    mark_not_existing_students_for_destruction

    @student_notes = fetch_student_notes
    @unities = fetch_unities
    @school_calendar_steps = steps_fetcher.steps
    @avaliations = fetch_avaliations
    reload_students_list

    @number_of_decimal_places = current_test_setting.number_of_decimal_places
    @any_student_exempted_from_discipline = any_student_exempted_from_discipline?
  end

  def update
    @avaliation_recovery_diary_record = AvaliationRecoveryDiaryRecord.find(params[:id]).localized

    # Reorganiza resource_params quando temos alunos com enturmacoes ativas e inativas
    reload_resource_params = list_students_by_active(resource_params.to_h)

    @avaliation_recovery_diary_record.assign_attributes(reload_resource_params)
    @avaliation_recovery_diary_record.recovery_diary_record.teacher_id = current_teacher_id
    @avaliation_recovery_diary_record.recovery_diary_record.current_user = current_user

    authorize @avaliation_recovery_diary_record

    if @avaliation_recovery_diary_record.save
      respond_with @avaliation_recovery_diary_record, location: avaliation_recovery_diary_records_path
    else
      set_options_by_user
      fetch_disciplines_by_classroom

      @number_of_decimal_places = current_test_setting.number_of_decimal_places
      reload_students_list if daily_note_students.present?

      render :edit
    end
  end

  def history
    @avaliation_recovery_diary_record = AvaliationRecoveryDiaryRecord.find(params[:id])

    authorize @avaliation_recovery_diary_record

    respond_with @avaliation_recovery_diary_record
  end

  def destroy
    @avaliation_recovery_diary_record = AvaliationRecoveryDiaryRecord.find(params[:id])

    @avaliation_recovery_diary_record.recovery_diary_record.destroy

    respond_with @avaliation_recovery_diary_record, location: avaliation_recovery_diary_records_path
  end

  private

  def fetch_avaliation_recovery_diary_records_by_user
    @avaliation_recovery_diary_records =
      apply_scopes(AvaliationRecoveryDiaryRecord)
        .select('DISTINCT ON (avaliation_recovery_diary_records.id, recovery_diary_records.recorded_at) avaliation_recovery_diary_records.*')
        .includes(:avaliation, recovery_diary_record: [:unity, :classroom, :discipline])
        .by_unity_id(current_unity.id)
        .by_classroom_id(@classrooms.map(&:id))
        .by_discipline_id(@disciplines.map(&:id))
        .by_teacher_id(current_teacher.id)
        .ordered
  end

  def resource_params
    params.require(:avaliation_recovery_diary_record).permit(
      :avaliation_id,
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
          :_destroy,
          :active
        ]
      ]
    )
  end

  def fetch_unities
    Unity.by_teacher(current_teacher.id).ordered
  end

  def fetch_classrooms
    Classroom.where(id: current_user_classroom).ordered
  end

  def fetch_disciplines
    Discipline.where(id: current_user_discipline).ordered
  end

  def mark_not_existing_students_for_destruction
    current_students.each do |current_student|
      is_student_in_recovery = daily_note_students.students.any? do |daily_note_student|
        current_student.student.id == daily_note_student.student.id
      end

      current_student.mark_for_destruction unless is_student_in_recovery
    end
  end

  def missing_students
    missing_students = []
    daily_note_students.students.each do |daily_note_student|
      is_missing = @avaliation_recovery_diary_record.recovery_diary_record.students.none? do |recovery_diary_record_student|
        recovery_diary_record_student.student.id == daily_note_student.student.id
      end
      missing_students << daily_note_student.student if is_missing
    end
    missing_students
  end

  def daily_note_students
    DailyNote.find_by_avaliation_id(@avaliation_recovery_diary_record.avaliation_id)
  end

  def add_missing_students
    missing_students.each do |missing_student|
      @avaliation_recovery_diary_record.recovery_diary_record.students.build(student: missing_student)
    end
  end

  def fetch_student_notes
    student_notes = DailyNoteStudent.by_avaliation(@avaliation_recovery_diary_record.avaliation).pluck(:student_id, :note).flatten
    Hash[*student_notes]
  end

  def current_students
    @avaliation_recovery_diary_record.recovery_diary_record.students
  end

  def fetch_avaliations
    Avaliation
      .by_discipline_id(@avaliation_recovery_diary_record.recovery_diary_record.discipline_id)
      .by_classroom_id(@avaliation_recovery_diary_record.recovery_diary_record.classroom_id)
      .ordered
  end

  def fetch_student_enrollments
    return unless @avaliation_recovery_diary_record.avaliation
    return unless @avaliation_recovery_diary_record.recovery_diary_record.recorded_at

    StudentEnrollmentsList.new(classroom: @avaliation_recovery_diary_record.recovery_diary_record.classroom,
                               grade: @avaliation_recovery_diary_record.avaliation.grade_ids,
                               discipline: @avaliation_recovery_diary_record.recovery_diary_record.discipline,
                               score_type: StudentEnrollmentScoreTypeFilters::NUMERIC,
                               date: @avaliation_recovery_diary_record.recovery_diary_record.recorded_at,
                               search_type: :by_date)
                          .student_enrollments
  end

  def reload_students_list
    return unless (student_enrollments = fetch_student_enrollments)

    recovery_diary_record = @avaliation_recovery_diary_record.recovery_diary_record

    return unless recovery_diary_record.recorded_at

    @students = []
    student_enrollments.each do |student_enrollment|
      if student = Student.find_by_id(student_enrollment.student_id)
        recovery_student = recovery_diary_record.students.find_by(student_id: student.id)
        note_student = recovery_student || recovery_diary_record.students.build(student_id: student.id, student: student)
        note_student.dependence = student_has_dependence?(student_enrollment, @avaliation_recovery_diary_record.recovery_diary_record.discipline)
        note_student.active = student_active_on_date?(student_enrollment)
        note_student.exempted_from_discipline = student_exempted_from_discipline?(
          student_enrollment, recovery_diary_record, @avaliation_recovery_diary_record
        )

        @students << note_student
      end
    end

    @normal_students = []
    @dependence_students = []
    @any_inactive_student = any_inactive_student?

    @students.each do |student|
      @normal_students << student if !student.dependence
      @dependence_students << student if student.dependence
    end
  end

  def student_has_dependence?(student_enrollment, discipline)
    StudentEnrollmentDependence
      .by_student_enrollment(student_enrollment)
      .by_discipline(discipline)
      .any?
  end

  def student_active_on_date?(student_enrollment)
    StudentEnrollment
      .where(id: student_enrollment)
      .by_classroom(@avaliation_recovery_diary_record.recovery_diary_record.classroom)
      .by_date(@avaliation_recovery_diary_record.recovery_diary_record.recorded_at)
      .any?
  end

  def any_inactive_student?
    any_inactive_student = false
    if @students
      @students.each do |student|
        any_inactive_student = true if !student.active
      end
    end
    any_inactive_student
  end

  def student_exempted_from_discipline?(student_enrollment, recovery_diary_record, avaliation_recovery_diary_record)
    return if recovery_diary_record.discipline.blank?

    discipline_id = recovery_diary_record.discipline.id
    test_date = avaliation_recovery_diary_record.avaliation.test_date

    step_number = fetch_step_number(avaliation_recovery_diary_record, recovery_diary_record.classroom_id, test_date)

    student_enrollment.exempted_disciplines
                      .by_discipline(discipline_id)
                      .by_step_number(step_number)
                      .any?
  end

  def fetch_step_number(avaliation_recovery_diary_record, classroom_id, date)
    school_calendar = avaliation_recovery_diary_record.avaliation.school_calendar

    school_calendar_classroom = school_calendar.classrooms.find_by_classroom_id(classroom_id)

    return school_calendar_classroom.classroom_step(date) if school_calendar_classroom.present?

    school_calendar.step(date).to_number
  end

  def any_student_exempted_from_discipline?
    (@students || []).any?(&:exempted_from_discipline)
  end

  def list_students_by_active(resource_params_hash)
    group_students = resource_params_hash['recovery_diary_record_attributes']['students_attributes'].group_by { |key, value| value['id'] }

    note_students_uniq = group_students.select { |_k, value| value.count == 1 }
                                       .values
                                       .flat_map { |student| student.map(&:second) }

    note_students_active = group_students.reject { |_k, value| value.count == 1 }
                                         .flat_map { |_k, value| value.map(&:second) }
                                         .reject { |student| student['active'] == 'false' }

    note_students_uniq.push(note_students_active)

    resource_params_hash['recovery_diary_record_attributes']['students_attributes'] = note_students_uniq.flatten

    resource_params_hash
  end

  def set_options_by_user
    return fetch_linked_by_teacher unless current_user.current_role_is_admin_or_employee?

    @classrooms ||= fetch_classrooms
    @disciplines ||= fetch_disciplines
  end

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(current_teacher.id, current_unity, current_school_year)
    @classrooms ||= @fetch_linked_by_teacher[:classrooms]
    @disciplines ||= @fetch_linked_by_teacher[:disciplines]
  end

  def fetch_disciplines_by_classroom
    return if current_user.current_role_is_admin_or_employee?

    classroom = @avaliation_recovery_diary_record.recovery_diary_record.classroom
    @disciplines = @disciplines.by_classroom(classroom).not_descriptor
  end

  def steps_fetcher
    classroom = if @avaliation_recovery_diary_record.present?
                  @avaliation_recovery_diary_record.recovery_diary_record.classroom
                else
                  current_user_classroom
                end

    @steps_fetcher ||= StepsFetcher.new(classroom)
  end
end
