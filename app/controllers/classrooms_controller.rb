class ClassroomsController < ApplicationController
  respond_to :json

  def index
    return unless teacher_id = current_teacher.try(:id)
    unity_id = params[:unity_id]
    score_type = params[:score_type]

    if score_type
      @classrooms = Classroom.by_unity_and_teacher(unity_id, teacher_id).by_score_type(ScoreTypes.value_for(score_type.upcase)).ordered.uniq
    else
      @classrooms = Classroom.by_unity_and_teacher(unity_id, teacher_id).ordered.uniq
    end
  end
end
