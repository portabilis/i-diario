class DisciplinesController < ApplicationController
  respond_to :json

  has_scope :by_unity_id
  has_scope :by_teacher_id
  has_scope :by_grade
  has_scope :by_classroom

  def index
    return unless current_teacher.present?

    params[:by_classroom] = params[:classroom_id]

    step_id = params[:step_id] || params[:school_calendar_classroom_step_id] || params[:school_calendar_step_id]

    classroom = Classroom.find(params[:classroom_id])
    step_number = StepsFetcher.new(classroom).step_by_id(step_id).try(:step_number)
    exempted_discipline_ids = ExemptedDisciplinesInStep.discipline_ids(classroom.id, step_number)

    @disciplines = apply_scopes(Discipline).by_teacher_id(current_teacher.id).order_by_sequence

    if params[:conceptual]
      @disciplines = @disciplines.by_score_type(ScoreTypes::CONCEPT, params[:student_id])
    end

    @disciplines = @disciplines.where.not(id: exempted_discipline_ids) if exempted_discipline_ids.present?

    @disciplines
  end

  def search
    params[:filter][:by_teacher_id] = current_user.teacher_id if params[:use_user_teacher]
    @disciplines = apply_scopes(Discipline).ordered

    render json: @disciplines
  end

  def search_grouped_by_knowledge_area
    disciplines = Discipline.by_teacher_and_classroom(params[:filter][:teacher_id], params[:filter][:classroom_id])
                            .grouped_by_knowledge_area

    render json: disciplines.as_json
  end
end
