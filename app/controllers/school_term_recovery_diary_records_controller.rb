class SchoolTermRecoveryDiaryRecordsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher
  before_action :require_current_school_calendar
  before_action :require_current_test_setting

  def index
    step_id = (params[:filter] || []).delete(:by_step_id)

    @school_term_recovery_diary_records = apply_scopes(SchoolTermRecoveryDiaryRecord)
      .includes(
        recovery_diary_record: [
          :unity,
          :classroom,
          :discipline
        ]
      )
      .by_classroom_id(current_user_classroom)
      .by_discipline_id(current_user_discipline)
      .ordered

    @school_term_recovery_diary_records = @school_term_recovery_diary_records.by_step_id(current_user_classroom, step_id) if step_id.present?

    authorize @school_term_recovery_diary_records
  end

  def new
    @school_term_recovery_diary_record = SchoolTermRecoveryDiaryRecord.new.localized
    @school_term_recovery_diary_record.build_recovery_diary_record
    @school_term_recovery_diary_record.recovery_diary_record.unity = current_user_unity

    @number_of_decimal_places = current_test_setting.number_of_decimal_places
  end

  def create
    @school_term_recovery_diary_record = SchoolTermRecoveryDiaryRecord.new.localized
    @school_term_recovery_diary_record.assign_attributes(resource_params)

    authorize @school_term_recovery_diary_record

    if @school_term_recovery_diary_record.save
      respond_with @school_term_recovery_diary_record, location: school_term_recovery_diary_records_path
    else
      @number_of_decimal_places = current_test_setting.number_of_decimal_places

      render :new
    end
  end

  def edit
    @school_term_recovery_diary_record = SchoolTermRecoveryDiaryRecord.find(params[:id]).localized
    @school_term_recovery_diary_record.step_id = steps_fetcher.step(@school_term_recovery_diary_record.recorded_at).try(:id)

    authorize @school_term_recovery_diary_record

    students_in_recovery = fetch_students_in_recovery
    mark_students_not_in_recovery_for_destruction(students_in_recovery)
    mark_exempted_disciplines(students_in_recovery)
    add_missing_students(students_in_recovery)

    @any_student_exempted_from_discipline = any_student_exempted_from_discipline?
    @number_of_decimal_places = current_test_setting.number_of_decimal_places
  end

  def update
    @school_term_recovery_diary_record = SchoolTermRecoveryDiaryRecord.find(params[:id]).localized
    @school_term_recovery_diary_record.assign_attributes(resource_params)

    authorize @school_term_recovery_diary_record

    if @school_term_recovery_diary_record.save
      respond_with @school_term_recovery_diary_record, location: school_term_recovery_diary_records_path
    else
      @number_of_decimal_places = current_test_setting.number_of_decimal_places

      render :edit
    end
  end

  def destroy
    @school_term_recovery_diary_record = SchoolTermRecoveryDiaryRecord.find(params[:id])

    @school_term_recovery_diary_record.destroy

    respond_with @school_term_recovery_diary_record, location: school_term_recovery_diary_records_path
  end

    def history
    @school_term_recovery_diary_record = SchoolTermRecoveryDiaryRecord.find(params[:id])

    authorize @school_term_recovery_diary_record

    respond_with @school_term_recovery_diary_record
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

  def decimal_places
    @school_term_recovery_diary_record.step.test_setting.number_of_decimal_places
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
    @school_term_recovery_diary_record.recovery_diary_record.students.each do |student|
      is_student_in_recovery = students_in_recovery.any? do |student_in_recovery|
        student.student.id == student_in_recovery.id
      end

      student.mark_for_destruction unless is_student_in_recovery
    end
  end

  def mark_exempted_disciplines(students_in_recovery)
    @school_term_recovery_diary_record.recovery_diary_record.students.each do |student|
      exempted_from_discipline = students_in_recovery.find do |student_in_recovery|
        student_in_recovery.id == student.student_id
      end.try(:exempted_from_discipline)

      student.exempted_from_discipline = exempted_from_discipline
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

  def any_student_exempted_from_discipline?
    @school_term_recovery_diary_record.recovery_diary_record.students.any?(&:exempted_from_discipline)
  end

  def api_configuration
    IeducarApiConfiguration.current
  end
end
