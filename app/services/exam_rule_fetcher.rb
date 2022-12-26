class ExamRuleFetcher
  def initialize(classroom, student)
    @classroom = classroom
    @student = student
  end

  def self.fetch(classroom, student)
    self.new(classroom, student).fetch
  end

  def fetch
    return if @classroom.classrooms_grades.none? { |classroom_grade| classroom_grade.exam_rule.present? }

    student_enrollment_classroom = StudentEnrollmentClassroom.by_student(@student)
                                                             .by_classroom(@classroom)
                                                             .by_date(Date.current)
                                                             &.first

    if student_enrollment_classroom.blank?
      student_enrollment_classroom = StudentEnrollmentClassroom.by_student(@student)
                                                               .by_classroom(@classroom)
                                                               .active
                                                               &.last
    end

    uses_differentiated_exam_rule(student_enrollment_classroom)

  end

  private

  def uses_differentiated_exam_rule(student_enrollment_classroom)
    grade_id = student_enrollment_classroom.classrooms_grade.grade_id
    classroom_grade = @classroom.classrooms_grades.find_by(grade_id: grade_id)

    if @student.uses_differentiated_exam_rule
      (classroom_grade.exam_rule.differentiated_exam_rule || classroom_grade.exam_rule)
    else
      classroom_grade.exam_rule
    end
  end
end
