class Api::V1::TeacherClassroomsController < Api::V1::BaseController
  respond_to :json

  def index
    teacher_id = params[:teacher_id]
    unity_id = params[:unity_id]
    return unless teacher_id && unity_id
    @classrooms = Classroom.by_unity_and_teacher(unity_id, teacher_id).ordered.uniq
  end
end
