class KnowledgeAreasController < ApplicationController
  respond_to :json

  def index
    return unless teacher_id = current_teacher.try(:id)
    classroom_id = params[:classroom_id]

     disciplines_ids = Discipline.by_teacher_and_classroom(teacher_id, classroom_id).ordered.uniq.map { |discipline| discipline.id }
     @knowledge_areas = KnowledgeArea.by_discipline_id(disciplines_ids)
  end
end
