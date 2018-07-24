class DisciplinesController < ApplicationController
  respond_to :json

  has_scope :by_unity_id
  has_scope :by_teacher_id
  has_scope :by_grade
  has_scope :by_classroom

  def index
    return unless current_teacher.present?

    if params[:classroom_id].present?
      params[:by_classroom] = params[:classroom_id]
    end

    calendar_step_id = params[:school_calendar_step_id]
    classroom_step_id = params[:school_calendar_classroom_step_id]

    if calendar_step_id || classroom_step_id
      disciplines_by_step_number = ExemptedDisciplinesInStep.new(params[:classroom_id])
      disciplines_by_step = disciplines_by_step_number.discipline_ids_by_classroom_step(classroom_step_id) if classroom_step_id
      disciplines_by_step = disciplines_by_step_number.discipline_ids_by_calendar_step(calendar_step_id) unless disciplines_by_step
    end

    @disciplines = apply_scopes(Discipline).by_teacher_id(current_teacher.id).order_by_sequence

    if disciplines_by_step
      @disciplines = @disciplines.where.not(id: disciplines_by_step)
    end
  end

  def search
    if(params[:use_user_teacher])
      params[:filter][:by_teacher_id] = current_user.teacher_id
    end
    @disciplines = apply_scopes(Discipline).ordered

    render json: @disciplines
  end
end
