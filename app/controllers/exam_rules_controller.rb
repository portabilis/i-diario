class ExamRulesController < ApplicationController
  def index
    classroom = Classroom.find(params[:classroom_id])
    @exam_rule = classroom.exam_rule

    render json: @exam_rule
  end
end
