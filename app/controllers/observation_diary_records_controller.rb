class ObservationDiaryRecordsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_school_calendar
  before_action :require_current_teacher

  def index
    @observation_diary_records = apply_scopes(ObservationDiaryRecord)
      .includes(:discipline, classroom: :unity)
      .by_unity(current_user_unity.id)
      .by_teacher(current_teacher.id)
      .ordered
  end

  def new
    @observation_diary_record = ObservationDiaryRecord.new.localized
    @observation_diary_record.school_calendar_id = current_school_calendar.id
    @observation_diary_record.teacher_id = current_teacher.id
    @observation_diary_record.date = Time.zone.today
  end

  def create
    @observation_diary_record = ObservationDiaryRecord.new(resource_params)

    authorize @observation_diary_record

    if @observation_diary_record.save
      respond_with @observation_diary_record, location: observation_diary_records_path
    else
      render :new
    end
  end

  def edit
    @observation_diary_record = ObservationDiaryRecord.find(params[:id]).localized

    authorize @observation_diary_record
  end

  def update
    @observation_diary_record = ObservationDiaryRecord.find(params[:id]).localized
    @observation_diary_record.assign_attributes(resource_params)

    authorize @observation_diary_record

    if @observation_diary_record.save
      respond_with @observation_diary_record, location: observation_diary_records_path
    else
      render :edit
    end
  end

  def destroy
    @observation_diary_record = ObservationDiaryRecord.find(params[:id])

    @observation_diary_record.destroy

    respond_with @observation_diary_record, location: observation_diary_records_path
  end

  def history
    @observation_diary_record = ObservationDiaryRecord.find(params[:id]).localized

    authorize @observation_diary_record
  end

  def unities
    @unities ||= Unity.by_teacher(current_teacher.id).ordered
  end
  helper_method :unities

  def classrooms
    @classrooms ||= Classroom.by_unity_and_teacher(
      current_user_unity.id,
      current_teacher.id
    )
    .ordered
  end
  helper_method :classrooms

  def disciplines
    @disciplines ||= Discipline.by_unity_id(current_user_unity.id)
      .by_teacher_id(current_teacher.id)
      .ordered
  end
  helper_method :disciplines

  private

  def resource_params
    parse_params
    params.require(:observation_diary_record).permit(
      :school_calendar_id,
      :teacher_id,
      :unity_id,
      :classroom_id,
      :discipline_id,
      :date,
      notes_attributes: [
        :id,
        :description,
        :_destroy,
        student_ids: []
      ]
    )
  end

  def parse_params
    return unless params['observation_diary_record']['notes_attributes'].present?

    params['observation_diary_record']['notes_attributes'].each do |_, v|
      v['student_ids'] = v['student_ids'].split(',')
    end
  end
end
