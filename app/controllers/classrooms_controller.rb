class ClassroomsController < ApplicationController
  respond_to :json

  def index
    return unless teacher_id = current_teacher.try(:id)
    unity_id = params[:unity_id]

    @classrooms = Classroom.joins(:teacher_discipline_classrooms).where(unity_id: unity_id, teacher_discipline_classrooms: { teacher_id: teacher_id}).ordered.uniq
  end
end
