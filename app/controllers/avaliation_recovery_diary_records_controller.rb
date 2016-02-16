class AvaliationRecoveryDiaryRecordsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher
  before_action :require_current_school_calendar
  before_action :require_current_test_setting

  def index
    @avaliation_recovery_diary_records = apply_scopes(AvaliationRecoveryDiaryRecord)
      .includes(
        :avaliation,
        recovery_diary_record: [
          :unity,
          :classroom,
          :discipline
        ]
      )
      .by_unity_id(current_user_unity.id)
      .by_teacher_id(current_teacher.id)
      .ordered

    authorize @avaliation_recovery_diary_records

    @classrooms = fetch_classrooms
    @disciplines = fetch_disciplines
    @school_calendar_steps = current_school_calendar.steps
  end

  def new
    @avaliation_recovery_diary_record = AvaliationRecoveryDiaryRecord.new.localized
    @avaliation_recovery_diary_record.build_recovery_diary_record
    @avaliation_recovery_diary_record.recovery_diary_record.unity = current_user_unity

    @unities = fetch_unities
    @classrooms = fetch_classrooms
    @school_calendar_steps = current_school_calendar.steps

    @number_of_decimal_places = current_test_setting.number_of_decimal_places
  end

  def create
    @avaliation_recovery_diary_record = AvaliationRecoveryDiaryRecord.new.localized
    @avaliation_recovery_diary_record.assign_attributes(resource_params)

    authorize @avaliation_recovery_diary_record

    if @avaliation_recovery_diary_record.save
      respond_with @avaliation_recovery_diary_record, location: avaliation_recovery_diary_records_path
    else
      @unities = fetch_unities
      @classrooms = fetch_classrooms
      @school_calendar_steps = current_school_calendar.steps
      @student_notes = fetch_student_notes
      @number_of_decimal_places = current_test_setting.number_of_decimal_places

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

    @number_of_decimal_places = current_test_setting.number_of_decimal_places
  end

  def update
    @avaliation_recovery_diary_record = AvaliationRecoveryDiaryRecord.find(params[:id]).localized
    @avaliation_recovery_diary_record.assign_attributes(resource_params)

    authorize @avaliation_recovery_diary_record

    if @avaliation_recovery_diary_record.save
      respond_with @avaliation_recovery_diary_record, location: avaliation_recovery_diary_records_path
    else
      @unities = fetch_unities
      @classrooms = fetch_classrooms
      @school_calendar_steps = current_school_calendar.steps
      @number_of_decimal_places = current_test_setting.number_of_decimal_places
      @student_notes = fetch_student_notes

      render :edit
    end
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
    Classroom.by_unity_and_teacher(
      current_user_unity.id,
      current_teacher.id
    )
    .ordered
  end

  def fetch_disciplines
    Discipline.by_unity_id(current_user_unity.id)
      .by_teacher_id(current_teacher.id)
      .ordered
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
end
