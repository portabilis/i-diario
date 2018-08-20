class DisciplinesController < ApplicationController
  respond_to :json

  has_scope :by_unity_id
  has_scope :by_teacher_id
  has_scope :by_grade
  has_scope :by_classroom

  def index
    return unless current_teacher.present?

    params[:by_classroom] = params[:classroom_id]

    classroom = Classroom.find(params[:classroom_id])
    step_number = StepsFetcher.new(classroom).steps.find(params[:step_id]).to_number
    exempted_discipline_ids = ExemptedDisciplinesInStep.discipline_ids(classroom.id, step_number)

    @disciplines = apply_scopes(Discipline).by_teacher_id(current_teacher.id).order_by_sequence

    if params[:conceptual]
      @disciplines = @disciplines.by_score_type(:concept, params[:student_id])
    end

    @disciplines = @disciplines.where.not(id: exempted_discipline_ids) if exempted_discipline_ids.present?

    @disciplines
  end

  def search
    params[:filter][:by_teacher_id] = current_user.teacher_id if params[:use_user_teacher]
    @disciplines = apply_scopes(Discipline).ordered

    render json: @disciplines
  end
end
