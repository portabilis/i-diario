class EnrollmentFromStudentFetcher
  def current_enrollments(student, classroom, date)
    aux = StudentEnrollmentClassroom.by_classroom(classroom)
                                    .by_student(student)
                                    .includes(:student_enrollment)
                                    .active
                                    .ordered
    aa = aux.map { |b|
      { id: b.student_enrollment_id, student_id: b.student_id, joined_at: b.joined_at, left_at: b.left_at }
    }
    aa
  end
end
