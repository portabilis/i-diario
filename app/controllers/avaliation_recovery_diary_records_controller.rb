class AvaliationRecoveryDiaryRecordsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_clasroom
  before_action :require_current_teacher
  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy]

  def index
    @avaliation_recovery_diary_records =
      apply_scopes(AvaliationRecoveryDiaryRecord)
      .includes(:avaliation, recovery_diary_record: [:unity, :classroom, :discipline])
      .by_unity_id(current_unity.id)
      .by_classroom_id(current_user_classroom)
      .by_discipline_id(current_user_discipline)
      .ordered

    authorize @avaliation_recovery_diary_records

    @classrooms = fetch_classrooms
    @disciplines = fetch_disciplines
    @school_calendar_steps = current_school_calendar.steps
  end

  def new
    @avaliation_recovery_diary_record = AvaliationRecoveryDiaryRecord.new.localized
    @avaliation_recovery_diary_record.build_recovery_diary_record
    @avaliation_recovery_diary_record.recovery_diary_record.unity = current_unity

    @unities = fetch_unities
    @classrooms = fetch_classrooms
    @school_calendar_steps = current_school_calendar.steps

    if current_test_setting.blank?
      flash[:error] = t('errors.avaliations.require_setting')

      redirect_to(avaliation_recovery_diary_records_path)
    end

    return if performed?

    @number_of_decimal_places = current_test_setting.number_of_decimal_places
  end

  def create
    @avaliation_recovery_diary_record = AvaliationRecoveryDiaryRecord.new.localized
    @avaliation_recovery_diary_record.assign_attributes(resource_params)
    @avaliation_recovery_diary_record.recovery_diary_record.teacher_id = current_teacher_id

    authorize @avaliation_recovery_diary_record

    if @avaliation_recovery_diary_record.save
      respond_with @avaliation_recovery_diary_record, location: avaliation_recovery_diary_records_path
    else
      @unities = fetch_unities
      @classrooms = fetch_classrooms
      @school_calendar_steps = current_school_calendar.steps
      @student_notes = fetch_student_notes
      @number_of_decimal_places = current_test_setting.number_of_decimal_places
      reload_students_list if daily_note_students.present?

      render :new
    end
  end

  def edit
    @avaliation_recovery_diary_record = AvaliationRecoveryDiaryRecord.find(params[:id]).localized

    authorize @avaliation_recovery_diary_record

    add_missing_students
    mark_not_existing_students_for_destruction

    @student_notes = fetch_student_notes
    @unities = fetch_unities
    @classrooms = fetch_classrooms
    @school_calendar_steps = current_school_calendar.steps
    @avaliations = fetch_avaliations
    reload_students_list

    @number_of_decimal_places = current_test_setting.number_of_decimal_places
    @any_student_exempted_from_discipline = any_student_exempted_from_discipline?
  end

  def update
    @avaliation_recovery_diary_record = AvaliationRecoveryDiaryRecord.find(params[:id]).localized
    @avaliation_recovery_diary_record.assign_attributes(resource_params)
    @avaliation_recovery_diary_record.recovery_diary_record.teacher_id = current_teacher_id
    @avaliation_recovery_diary_record.recovery_diary_record.current_user = current_user

    authorize @avaliation_recovery_diary_record

    if @avaliation_recovery_diary_record.save
      respond_with @avaliation_recovery_diary_record, location: avaliation_recovery_diary_records_path
    else
      @unities = fetch_unities
      @classrooms = fetch_classrooms
      @school_calendar_steps = current_school_calendar.steps
      @number_of_decimal_places = current_test_setting.number_of_decimal_places
      @student_notes = fetch_student_notes
      reload_students_list

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

    @avaliation_recovery_diary_record.destroy

    respond_with @avaliation_recovery_diary_record, location: avaliation_recovery_diary_records_path
  end

  private

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
          :_destroy
        ]
      ]
    )
  end

  def fetch_unities
    Unity.by_teacher(current_teacher.id).ordered
  end

  def fetch_classrooms
    Classroom.where(id: current_user_classroom)
    .ordered
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
                               discipline: @avaliation_recovery_diary_record.recovery_diary_record.discipline,
                               score_type: StudentEnrollmentScoreTypeFilters::NUMERIC,
                               date: @avaliation_recovery_diary_record.recovery_diary_record.recorded_at,
                               search_type: :by_date)
                          .student_enrollments
  end

  def reload_students_list
    student_enrollments = fetch_student_enrollments

    return unless fetch_student_enrollments
    return unless @avaliation_recovery_diary_record.recovery_diary_record.recorded_at

    @students = []

    student_enrollments.each do |student_enrollment|
      if student = Student.find_by_id(student_enrollment.student_id)
        recovery_diary_record = @avaliation_recovery_diary_record.recovery_diary_record
        note_student = (recovery_diary_record.students.where(student_id: student.id).first || recovery_diary_record.students.build(student_id: student.id, student: student))
        note_student.dependence = student_has_dependence?(student_enrollment, @avaliation_recovery_diary_record.recovery_diary_record.discipline)
        note_student.active = student_active_on_date?(student_enrollment)
        note_student.exempted_from_discipline = student_exempted_from_discipline?(student_enrollment, recovery_diary_record, @avaliation_recovery_diary_record)
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
    step_number = avaliation_recovery_diary_record.avaliation.school_calendar.step(test_date).to_number

    student_enrollment.exempted_disciplines.by_discipline(discipline_id)
                                           .by_step_number(step_number)
                                           .any?
  end

  def any_student_exempted_from_discipline?
    (@students || []).any?(&:exempted_from_discipline)
  end
end
