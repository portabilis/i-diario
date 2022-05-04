class ExamRulesController < ApplicationController
  def index
    classroom = Classroom.find_by(id: params[:classroom_id])
    student = Student.find_by(id: params[:student_id])

    return render json: nil if classroom.blank?

    classroom_grades = classroom.classrooms_grades
    classroom_grades = classroom_grades.by_student_id(student.id) if student.present?
    classroom_grade = classroom_grades&.first

    return render json: nil if classroom_grade.blank?

    @exam_rule = classroom_grade&.exam_rule

    return render json: nil if @exam_rule.blank?

    @exam_rule = @exam_rule.differentiated_exam_rule || @exam_rule if student.try(:uses_differentiated_exam_rule)

    absence_type_definer = FrequencyTypeDefiner.new(classroom, current_teacher, @exam_rule, year: classroom.year)
    absence_type_definer.define!

    @exam_rule&.allow_frequency_by_discipline = (absence_type_definer.frequency_type == FrequencyTypes::BY_DISCIPLINE)

    render json: @exam_rule
  end
end
