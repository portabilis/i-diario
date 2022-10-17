class ExamRulesController < ApplicationController
  def index
    classroom = Classroom.find_by(id: params[:classroom_id])
    student = Student.find_by(id: params[:student_id])
    classroom_grade_by_student = nil

    if student.present?
      student_enrollment_classroom = StudentEnrollmentClassroom.by_student(student).by_classroom(classroom).last
      classroom_grade_by_student = student_enrollment_classroom.classrooms_grade
    end

    return render json: nil if classroom.blank?

    classroom_grades = classroom.classrooms_grades.includes(:exam_rule)
    classroom_grade = classroom_grade_by_student || classroom_grades.first

    return render json: nil if classroom_grade.blank?

    @exam_rule = classroom_grade.exam_rule

    return render json: nil if @exam_rule.blank?

    @exam_rule = @exam_rule.differentiated_exam_rule || @exam_rule if student.try(:uses_differentiated_exam_rule)

    absence_type_definer = FrequencyTypeDefiner.new(classroom, current_teacher, @exam_rule, year: classroom.year)
    absence_type_definer.define!

    @exam_rule&.allow_frequency_by_discipline = (absence_type_definer.frequency_type == FrequencyTypes::BY_DISCIPLINE)

    render json: @exam_rule
  end

  def for_school_term_type_recovery
    classroom = Classroom.find_by(id: params[:classroom_id])

    return render json: nil if classroom.nil?

    classroom_grades = classroom.classrooms_grades.includes(:exam_rule)

    classroom_grade = classroom_grades.detect do |classroom_grade|
      classroom_grade.exam_rule.recovery_type != (RecoveryTypes::DONT_USE)
    end

    return render json: nil if classroom_grade.nil?

    @exam_rule = classroom_grade.exam_rule
    absence_type_definer = FrequencyTypeDefiner.new(classroom, current_teacher, @exam_rule, year: classroom.year)
    absence_type_definer.define!
    @exam_rule.allow_frequency_by_discipline = (absence_type_definer.frequency_type == FrequencyTypes::BY_DISCIPLINE)

    render json: @exam_rule
  end
end
