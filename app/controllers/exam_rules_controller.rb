class ExamRulesController < ApplicationController
  def index
    classroom = Classroom.find(params[:classroom_id])
    student = (params[:student_id] && Student.find(params[:student_id]) ) || nil
    @exam_rule = classroom.exam_rule
    @exam_rule = @exam_rule.differentiated_exam_rule || @exam_rule if student.try(:uses_differentiated_exam_rule)
    absence_type_definer = FrequencyTypeDefiner.new(classroom, current_teacher, @exam_rule)
    absence_type_definer.define!
    @exam_rule.allow_frequency_by_discipline = (absence_type_definer.frequency_type == FrequencyTypes::BY_DISCIPLINE)
    render json: @exam_rule
  end
end
