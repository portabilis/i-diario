class KnowledgeAreasController < ApplicationController
  respond_to :json

  has_scope :by_unity
  has_scope :by_grade

  def index
    return unless current_teacher.present?

    @knowledge_areas = apply_scopes(KnowledgeArea).by_teacher(current_teacher)
      .ordered

    if params[:classroom_id].present?
      classroom_id = params[:classroom_id]

      disciplines_ids = Discipline.by_teacher_and_classroom(current_teacher.id, classroom_id)
        .ordered
        .uniq
        .map { |discipline| discipline.id }

      @knowledge_areas = @knowledge_areas.by_discipline_id(disciplines_ids)
    end

    @knowledge_areas
  end
end
