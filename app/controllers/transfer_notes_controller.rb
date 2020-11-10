class TransferNotesController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_clasroom
  before_action :require_current_teacher
  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy]

  def index
    step_id = (params[:filter] || []).delete(:by_step)

    @transfer_notes = apply_scopes(TransferNote).includes(:classroom, :discipline, :student)
                                                .by_classroom_id(current_user_classroom)
                                                .by_discipline_id(current_user_discipline)

    if step_id.present?
      @transfer_notes = @transfer_notes.by_step_id(current_user_classroom, step_id)
      params[:filter][:by_step] = step_id
    end

    authorize @transfer_notes
  end

  def new
    @transfer_note = TransferNote.new(
      unity_id: current_unity.id
    ).localized

    authorize @transfer_note
  end

  def create
    @transfer_note = TransferNote.new.localized
    @transfer_note.assign_attributes(resource_params)
    @transfer_note.step_number = @transfer_note.step.try(:step_number)
    @transfer_note.teacher = current_teacher

    authorize @transfer_note

    if @transfer_note.save
      respond_with @transfer_note, location: transfer_notes_path
    else
      render :new
    end
  end

  def edit
    @transfer_note = TransferNote.find(params[:id]).localized
    @transfer_note.step_id = steps_fetcher.step(@transfer_note.step_number).try(:id)
    @students_ordered = @transfer_note.daily_note_students.ordered

    authorize @transfer_note
  end

  def update
    @transfer_note = TransferNote.find(params[:id]).localized
    @transfer_note.current_user = current_user
    @transfer_note.assign_attributes(resource_params)

    authorize @transfer_note

    if @transfer_note.save
      respond_with @transfer_note, location: transfer_notes_path
    else
      render :new
    end
  end

  def current_notes
    return unless params[:step_id].present? && params[:student_id].present? && params[:recorded_at].present?

    step = StepsFetcher.new(Classroom.find(params[:classroom_id])).step_by_id(params[:step_id])
    end_date = step.end_at > params[:recorded_at].to_date ? params[:recorded_at].to_date : step.end_at
    avaliations = Avaliation.by_classroom_id(params[:classroom_id])
                            .by_discipline_id(params[:discipline_id])
                            .by_teacher(current_teacher.id)
                            .by_test_date_between(step.start_at, end_date)
                            .ordered_asc

    @daily_note_students = avaliations.map do |avaliation|
      daily_note = DailyNote.find_or_create_by!(
        avaliation_id: avaliation.id
      ).localized

      DailyNoteStudent.find_or_initialize_by(
        daily_note_id: daily_note.id,
        student_id: params[:student_id]
      ).localized
    end

    render(json: @daily_note_students, include: { daily_notes: [:avaliation] })
  end

  def history
    @transfer_note = TransferNote.find(params[:id]).localized

    authorize @transfer_note

    respond_with @transfer_note
  end

  def destroy
    @transfer_note = TransferNote.find(params[:id])

    authorize @transfer_note

    @transfer_note.destroy

    respond_with(@transfer_note, location: transfer_notes_path)
  end

  private

  def resource_params
    params.require(:transfer_note).permit(
      :unity_id,
      :classroom_id,
      :discipline_id,
      :recorded_at,
      :student_id,
      :step_id,
      daily_note_students_attributes: [
        :id,
        :student_id,
        :daily_note_id,
        :note,
        :active
      ]
    )
  end

  def steps_fetcher
    @steps_fetcher ||= StepsFetcher.new(current_user_classroom)
  end

  def unities
    @unities = [@transfer_note.classroom.present? ? @transfer_note.classroom.unity : current_unity]
  end
  helper_method :unities

  def classrooms
    @classrooms ||= Classroom.by_unity_and_teacher(
      current_unity.id,
      current_teacher.id
    )
    .ordered
  end
  helper_method :classrooms

  def disciplines
    @disciplines = []
  end
  helper_method :disciplines

  def students
    @students = (@transfer_note.student_id.present? ? [@transfer_note.student] : [])
  end
  helper_method :students
end
