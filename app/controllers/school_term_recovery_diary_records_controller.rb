class SchoolTermRecoveryDiaryRecordsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher
  before_action :require_current_school_calendar
  before_action :require_current_test_setting

  def index
    @school_term_recovery_diary_records = apply_scopes(SchoolTermRecoveryDiaryRecord)
      .includes(
        :school_calendar_step,
        recovery_diary_record: [
          :unity,
          :classroom,
          :discipline
        ]
      )
      .filter(filtering_params(params[:search]))
      .by_classroom_id(current_user_classroom)
      .by_discipline_id(current_user_discipline)
      .ordered

    authorize @school_term_recovery_diary_records

    @classrooms = fetch_classrooms
    @disciplines = fetch_disciplines
    @school_calendar_steps = current_school_calendar.steps
  end

  def new
    @school_term_recovery_diary_record = SchoolTermRecoveryDiaryRecord.new.localized
    @school_term_recovery_diary_record.build_recovery_diary_record
    @school_term_recovery_diary_record.recovery_diary_record.unity = current_user_unity

    @school_calendar_steps = current_school_calendar.steps
  end

  def create
    @school_term_recovery_diary_record = SchoolTermRecoveryDiaryRecord.new.localized
    @school_term_recovery_diary_record.assign_attributes(resource_params)

    authorize @school_term_recovery_diary_record

    if @school_term_recovery_diary_record.save
      respond_with @school_term_recovery_diary_record, location: school_term_recovery_diary_records_path
    else
      @school_calendar_steps = current_school_calendar.steps

      render :new
    end
  end

  def edit
    @school_term_recovery_diary_record = SchoolTermRecoveryDiaryRecord.find(params[:id]).localized

    authorize @school_term_recovery_diary_record

    students_in_recovery = fetch_students_in_recovery
    mark_students_not_in_recovery_for_destruction(students_in_recovery)
    add_missing_students(students_in_recovery)

    @school_calendar_steps = current_school_calendar.steps
  end

  def update
    @school_term_recovery_diary_record = SchoolTermRecoveryDiaryRecord.find(params[:id]).localized
    @school_term_recovery_diary_record.assign_attributes(resource_params)

    authorize @school_term_recovery_diary_record

    if @school_term_recovery_diary_record.save
      respond_with @school_term_recovery_diary_record, location: school_term_recovery_diary_records_path
    else
      @school_calendar_steps = current_school_calendar.steps

      render :edit
    end
  end

  def destroy
    @school_term_recovery_diary_record = SchoolTermRecoveryDiaryRecord.find(params[:id])

    @school_term_recovery_diary_record.destroy

    respond_with @school_term_recovery_diary_record, location: school_term_recovery_diary_records_path
  end

  private

  def resource_params
    params.require(:school_term_recovery_diary_record).permit(
      :school_calendar_step_id,
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

  def filtering_params(params)
    params = {} unless params
    params.slice(
      :by_classroom_id,
      :by_discipline_id,
      :by_school_calendar_step_id,
      :by_recorded_at
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
    Discipline.where(id: current_user_discipline)
      .ordered
  end

  def fetch_students_in_recovery
    StudentsInRecoveryFetcher.new(
      api_configuration,
      @school_term_recovery_diary_record.recovery_diary_record.classroom_id,
      @school_term_recovery_diary_record.recovery_diary_record.discipline_id,
      @school_term_recovery_diary_record.school_calendar_step_id,
      @school_term_recovery_diary_record.recovery_diary_record.recorded_at
    )
    .fetch
  end

  def mark_students_not_in_recovery_for_destruction(students_in_recovery)
    @school_term_recovery_diary_record.recovery_diary_record.students.each do |student|
      is_student_in_recovery = students_in_recovery.any? do |student_in_recovery|
        student.student.id == student_in_recovery.id
      end

      student.mark_for_destruction unless is_student_in_recovery
    end
  end

  def add_missing_students(students_in_recovery)
    students_missing = students_in_recovery.select do |student_in_recovery|
      @school_term_recovery_diary_record.recovery_diary_record.students.none? do |student|
        student.student.id == student_in_recovery.id
      end
    end

    students_missing.each do |student_missing|
      @school_term_recovery_diary_record.recovery_diary_record.students.build(student: student_missing)
    end
  end

  def api_configuration
    IeducarApiConfiguration.current
  end
end
