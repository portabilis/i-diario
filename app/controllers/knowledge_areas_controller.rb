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
        .distinct
        .map { |discipline| discipline.id }

      @knowledge_areas = @knowledge_areas.by_discipline_id(disciplines_ids)
    end

    if params[:grade_id].present? && params[:unity_id].present?
      grade_id = params[:grade_id]
      unity_id = params[:unity_id]
      year = current_school_calendar.year
      classrooms = Classroom.by_grade(grade_id).by_year(year).by_unity(unity_id).distinct
      disciplines_ids = Discipline.by_teacher_and_classroom(current_teacher.id, classrooms.map(&:id))
                                  .ordered
                                  .distinct
                                  .map { |discipline| discipline.id }

      @knowledge_areas = @knowledge_areas.by_discipline_id(disciplines_ids)
    end

    @knowledge_areas
  end
end
