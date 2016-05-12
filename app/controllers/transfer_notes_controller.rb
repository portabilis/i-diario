class TransferNotesController < ApplicationController
  before_action :require_current_teacher
  before_action :require_current_school_calendar
  has_scope :page, default: 1
  has_scope :per, default: 10

  def index
    @transfer_notes = apply_scopes(TransferNote.all)
    authorize @transfer_notes
  end

  def new
    @transfer_note = TransferNote.new(
      unity_id: current_user_unity.id
    )

    authorize @transfer_note
  end

  def create
  end

  private

  def unities
    @unities = [ current_user_unity ]
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
    @disciplines = []
  end
  helper_method :disciplines

  def school_calendar_steps
    @school_calendar_steps ||= current_school_calendar.steps
  end
  helper_method :school_calendar_steps
end
