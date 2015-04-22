class DisciplinesController < ApplicationController
  respond_to :json

  def index
    return unless teacher_id = current_teacher.try(:id)
    classroom_id = params[:classroom_id]

    @disciplines = Discipline.joins(:teacher_discipline_classrooms).where(teacher_discipline_classrooms: { teacher_id: teacher_id, classroom_id: classroom_id}).ordered.uniq
  end
end
