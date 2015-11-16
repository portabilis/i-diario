class Api::V1::ExamRulesController < Api::V1::BaseController
  respond_to :json

  def index
    classroom = Classroom.find(params[:classroom_id])

    render json: classroom.exam_rule
  end
end