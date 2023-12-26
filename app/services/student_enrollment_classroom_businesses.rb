class StudentEnrollmentClassroomBusinesses

  attr_accessor :year

  def generate_sequence(student_enrollment, student_enrollment_classroom, student_enrollment_classroom_record)
    self.year = student_enrollment_classroom&.classrooms_grade&.year
    sequencial_fechamento = student_enrollment_classroom_record.sequencial_fechamento
    student_enrollment_last = student_enrollment_last(student_enrollment)
    return sequencial_fechamento if student_enrollment_last.nil?

    new_sequence(sequencial_fechamento, student_enrollment_classroom, student_enrollment_last)
  end

  private

  def new_sequence(sequencial_fechamento, student_enrollment_classroom, student_enrollment_last)
    classroom_ids = student_enrollment_last.student_enrollment_classrooms.map { |student_enrollment_classroom|
      student_enrollment_classroom&.classrooms_grade&.classroom_id
    }

    if same_enrollment_classroom?(classroom_ids) && student_enrollment_classroom
      student_enrollment_classroom.sequence
    else
      sequencial_fechamento
    end
  end

  def same_enrollment_classroom?(classroom_ids)
    classroom_ids.last(2).count.eql?(2) && classroom_ids.last(2).uniq.count.eql?(1)
  end

  def student_enrollment_last(student_enrollment)
    enrollments_in_year = StudentEnrollment.active.by_year(year).by_student(student_enrollment.student.try(:id)).distinct

    if enrollments_in_year.size > 1
      enrollments_in_year.last
    end
  end
end
