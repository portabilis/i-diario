class TeacherAvaliationsController < ApplicationController
  respond_to :json

  def index
    return unless teacher_id = current_teacher.try(:id)
    classroom_id = params[:classroom_id]
    discipline_id = params[:discipline_id]

    @avaliations = Avaliation.teacher_avaliations(teacher_id, classroom_id, discipline_id).ordered.distinct
  end
end
