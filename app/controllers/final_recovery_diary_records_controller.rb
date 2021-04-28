class FinalRecoveryDiaryRecordsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_clasroom
  before_action :require_current_teacher
  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy]

  def index
    @final_recovery_diary_records =
      apply_scopes(FinalRecoveryDiaryRecord)
      .includes(recovery_diary_record: [:unity, :classroom, :discipline])
      .filter(filtering_params(params[:search]))
      .by_unity_id(current_unity.id)
      .by_classroom_id(current_user_classroom)
      .by_discipline_id(current_user_discipline)
      .ordered

    authorize @final_recovery_diary_records

    @classrooms = fetch_classrooms
    @disciplines = fetch_disciplines
  end

  def new
    @final_recovery_diary_record = FinalRecoveryDiaryRecord.new.localized
    @final_recovery_diary_record.school_calendar = current_school_calendar
    @final_recovery_diary_record.build_recovery_diary_record
    @final_recovery_diary_record.recovery_diary_record.unity = current_unity

    number_of_decimal_places
  end

  def create
    @final_recovery_diary_record = FinalRecoveryDiaryRecord.new.localized
    @final_recovery_diary_record.assign_attributes(resource_params)
    @final_recovery_diary_record.recovery_diary_record.teacher_id = current_teacher_id

    authorize @final_recovery_diary_record

    if @final_recovery_diary_record.save
      respond_with @final_recovery_diary_record, location: final_recovery_diary_records_path
    else
      number_of_decimal_places

      students_in_final_recovery = fetch_students_in_final_recovery
      decorate_students(students_in_final_recovery)

      render :new
    end
  end

  def edit
    @final_recovery_diary_record = FinalRecoveryDiaryRecord.find(params[:id]).localized

    authorize @final_recovery_diary_record

    students_in_final_recovery = fetch_students_in_final_recovery
    add_missing_students(students_in_final_recovery)
    @final_recovery_diary_record.recovery_diary_record.students.each do |record_student|
      record_student.student = fetch_student_in_final_recovery(record_student.student.id)
    end

    number_of_decimal_places
  end

  def update
    @final_recovery_diary_record = FinalRecoveryDiaryRecord.find(params[:id]).localized
    @final_recovery_diary_record.assign_attributes(resource_params)
    @final_recovery_diary_record.recovery_diary_record.teacher_id = current_teacher_id
    @final_recovery_diary_record.recovery_diary_record.current_user = current_user

    authorize @final_recovery_diary_record

    students_in_final_recovery = fetch_students_in_final_recovery

    if @final_recovery_diary_record.save
      respond_with @final_recovery_diary_record, location: final_recovery_diary_records_path
    else
      number_of_decimal_places

      render :edit
    end
  end

  def destroy
    @final_recovery_diary_record = FinalRecoveryDiaryRecord.find(params[:id])

    @final_recovery_diary_record.destroy

    respond_with @final_recovery_diary_record, location: final_recovery_diary_records_path
  end

  def history
    @final_recovery_diary_record = FinalRecoveryDiaryRecord.find(params[:id])

    authorize @final_recovery_diary_record

    respond_with @final_recovery_diary_record
  end

  private

  def resource_params
    params.require(:final_recovery_diary_record).permit(
      :school_calendar_id,
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

  def fetch_students_in_final_recovery
    return unless @final_recovery_diary_record.recovery_diary_record.classroom_id && @final_recovery_diary_record.recovery_diary_record.discipline_id

    StudentsInFinalRecoveryFetcher.new(api_configuration)
      .fetch(
        @final_recovery_diary_record.recovery_diary_record.classroom_id,
        @final_recovery_diary_record.recovery_diary_record.discipline_id
      )
  end

  def fetch_student_in_final_recovery(student_id)
    return unless @final_recovery_diary_record.recovery_diary_record.classroom_id && @final_recovery_diary_record.recovery_diary_record.discipline_id

    StudentInFinalRecoveryFetcher.new(api_configuration)
      .fetch(
        @final_recovery_diary_record.recovery_diary_record.classroom_id,
        @final_recovery_diary_record.recovery_diary_record.discipline_id,
        student_id
      )
  end

  def add_missing_students(students_in_final_recovery)
    current_students_ids = @final_recovery_diary_record.recovery_diary_record.students.map(&:student_id)

    students_missing = students_in_final_recovery.select do |student_in_final_recovery|
      !current_students_ids.include?(student_in_final_recovery.id)
    end

    students_missing.each do |student_missing|
      @final_recovery_diary_record.recovery_diary_record.students.build(student: student_missing)
    end
  end

  def decorate_students(students_in_final_recovery)
    @final_recovery_diary_record.recovery_diary_record.students.reject(&:marked_for_destruction?).each do |student|
      student.student = students_in_final_recovery.find { |student_in_final_recovery| student_in_final_recovery.id == student.student_id }
    end
  end

  def api_configuration
    IeducarApiConfiguration.current
  end

  def test_setting(classroom, step)
    TestSettingFetcher.current(classroom, step)
  end

  def number_of_decimal_places
    @number_of_decimal_places = test_setting(
      current_user_classroom,
      @final_recovery_diary_record.school_calendar.steps.to_a.last
    ).number_of_decimal_places
  end
end
