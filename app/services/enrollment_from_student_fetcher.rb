class EnrollmentFromStudentFetcher
  def current_enrollments(student, classroom, date)
    aux = StudentEnrollment.by_student(student)
                           .by_date(date[0])
                           .active
                           .ordered
    puts aux.as_json(include: {
      student_enrollment_classrooms
    })
    aux
  end
end
