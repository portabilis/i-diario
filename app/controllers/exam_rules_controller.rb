class ExamRulesController < ApplicationController
  def index
    classroom = Classroom.find(params[:classroom_id])
    @exam_rule = classroom.exam_rule
    absence_type_definer = FrequencyTypeDefiner.new(classroom, current_teacher)
    absence_type_definer.define!
    @exam_rule.allow_frequency_by_discipline = (absence_type_definer.frequency_type == FrequencyTypes::BY_DISCIPLINE)
    render json: @exam_rule
  end
end
