class ObservationDiaryRecordsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_classroom
  before_action :require_current_teacher
  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy]

  def index
    set_options_by_user
    set_filters

    @observation_diary_records = apply_scopes(ObservationDiaryRecord)
      .includes(:discipline, :students, classroom: :unity)
      .by_classroom(@classrooms.map(&:id))
      .by_discipline(@disciplines.map(&:id).push(nil))
      .ordered

    @students = fetch_students_with_observation_diary_records
  end

  def show
    @observation_diary_record = ObservationDiaryRecord.find(params[:id]).localized

    @observation_record_report_form = ObservationRecordReportForm.new(
      teacher_id: @observation_diary_record.teacher.id,
      discipline_id: @observation_diary_record.discipline.id,
      unity_id: @observation_diary_record.unity_id,
      classroom_id: @observation_diary_record.classroom.id,
      start_at: @observation_diary_record.date,
      end_at: @observation_diary_record.date,
      current_user_id: current_user.id
    ).localized

    if @observation_record_report_form.valid?
      observation_record_report = ObservationRecordReport.new(
        current_entity_configuration,
        @observation_record_report_form
      ).build
      send_pdf(t("routes.observation_record"), observation_record_report.render)
    else
      render @observation_diary_records
    end
  end

  def new
    @observation_diary_record = ObservationDiaryRecord.new.localized
    @observation_diary_record.school_calendar_id = current_school_calendar.id
    @observation_diary_record.teacher = current_teacher
    @observation_diary_record.date = Time.zone.today
    @allow_discipline_edit = false
  end

  def create
    @observation_diary_record = ObservationDiaryRecord.new(resource_params.to_unsafe_h)
    @observation_diary_record.teacher = current_teacher

    authorize @observation_diary_record

    if @observation_diary_record.save
      respond_with @observation_diary_record, location: observation_diary_records_path
    else
      begin
        resource_params[:date].to_date
      rescue ArgumentError
        @observation_diary_record.date = ''
      end
      render :new
    end
  end

  def edit
    @observation_diary_record = ObservationDiaryRecord.find(params[:id]).localized
    @allow_discipline_edit = @observation_diary_record.discipline.blank?
    authorize @observation_diary_record
  end

  def update
    @observation_diary_record = ObservationDiaryRecord.find(params[:id])
    @observation_diary_record.current_user = current_user
    @observation_diary_record.assign_attributes(resource_params.to_unsafe_h)

    authorize @observation_diary_record

    if @observation_diary_record.save
      respond_with @observation_diary_record, location: observation_diary_records_path
    else
      has_discipline_error = @observation_diary_record.errors[:discipline_id].present?
      discipline_blank = @observation_diary_record.discipline.blank?
      @allow_discipline_edit = has_discipline_error || discipline_blank
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

  def fetch_students_by_classroom
    students = Student.joins(observation_diary_record_note_students: :observation_diary_record_note)
                      .joins(
                        'INNER JOIN observation_diary_records ' \
                        'ON observation_diary_records.id = observation_diary_record_notes.observation_diary_record_id'
                      )
                      .where(observation_diary_records: { classroom_id: params[:classroom_id] })
                      .distinct
                      .ordered
                      .pluck(:id, :name)

    students_data = students.map { |id, name| { id: id, name: name } }

    render json: students_data.to_json
  end

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
      observation_diary_record_attachments_attributes: [
        :id,
        :attachment,
        :_destroy
      ],
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
    @classrooms ||= @fetch_linked_by_teacher[:classrooms]
    @disciplines ||= @fetch_linked_by_teacher[:disciplines]
  end

  def set_filters
    params[:filter] ||= {}
    params[:filter][:by_classroom] ||= current_user_classroom.id
    params[:filter][:by_discipline] ||= current_user_discipline.id

    @filter = OpenStruct.new(params[:filter])
  end

  def fetch_students_with_observation_diary_records
    Student.joins(observation_diary_record_note_students: :observation_diary_record_note)
           .where(observation_diary_record_notes: { observation_diary_record_id: @observation_diary_records })
           .distinct
           .ordered
  end
end
