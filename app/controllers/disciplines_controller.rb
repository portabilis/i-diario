class DisciplinesController < ApplicationController
  respond_to :json

  def index
    return unless teacher_id = current_teacher.try(:id)
    classroom_id = params[:classroom_id]

    @disciplines = Discipline.by_teacher_and_classroom(teacher_id, classroom_id).ordered.uniq
  end
end
