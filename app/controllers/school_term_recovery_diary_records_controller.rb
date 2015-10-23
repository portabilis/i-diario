class SchoolTermRecoveryDiaryRecordsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher
  before_action :require_current_school_calendar

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
      .by_unity_id(current_user_unity.id)
      .by_teacher_id(current_teacher.id)
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

    @unities = fetch_unities
    @classrooms = fetch_classrooms
    @school_calendar_steps = current_school_calendar.steps
  end

  def create
    @school_term_recovery_diary_record = SchoolTermRecoveryDiaryRecord.new.localized
    @school_term_recovery_diary_record.assign_attributes(resource_params)

    authorize @school_term_recovery_diary_record

    if @school_term_recovery_diary_record.save
      respond_with @school_term_recovery_diary_record, location: school_term_recovery_diary_records_path
    else
      @unities = fetch_unities
      @classrooms = fetch_classrooms
      @school_calendar_steps = current_school_calendar.steps

      render :new
    end
  end

  def edit
    @school_term_recovery_diary_record = SchoolTermRecoveryDiaryRecord.find(params[:id]).localized

    authorize @school_term_recovery_diary_record

    @unities = fetch_unities
    @classrooms = fetch_classrooms
    @school_calendar_steps = current_school_calendar.steps
  end

  def update
    @school_term_recovery_diary_record = SchoolTermRecoveryDiaryRecord.find(params[:id]).localized
    @school_term_recovery_diary_record.assign_attributes(resource_params)

    authorize @school_term_recovery_diary_record

    if @school_term_recovery_diary_record.save
      respond_with @school_term_recovery_diary_record, location: school_term_recovery_diary_records_path
    else
      @unities = fetch_unities
      @classrooms = fetch_classrooms
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
end
