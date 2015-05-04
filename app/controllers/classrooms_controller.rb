class ClassroomsController < ApplicationController
  respond_to :json

  def index
    return unless teacher_id = current_teacher.try(:id)
    unity_id = params[:unity_id]

    @classrooms = Classroom.by_unity_and_teacher(unity_id, teacher_id).ordered.uniq
  end
end
