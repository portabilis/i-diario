class EnrollmentFromStudentFetcher
  def current_enrollment(student, classroom, date)
    StudentEnrollment.by_student(student)
                     .by_classroom(classroom)
                     .by_date(date)
                     .active
                     .ordered
                     .last
  end
end
