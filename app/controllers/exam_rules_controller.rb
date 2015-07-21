class ExamRulesController < ApplicationController
  respond_to :json

  def index
    classroom_id = params[:classroom_id]
    @exam_rule = Classroom.find(classroom_id).exam_rule
  end
end
