class EnrollmentFromStudentFetcher
  def current_enrollments(students, classroom, dates)
    students_hashes = {}
    enrollments_classrooms = StudentEnrollmentClassroom.by_classroom(classroom)
                                                       .by_student(students)
                                                       .includes(student_enrollment: :student)
                                                       .active
                                                       .ordered

    dates.each do |date|
      enrollments_classrooms.each do |enrollment_classroom|
        joined_at = enrollment_classroom.joined_at.to_date
        left_at = enrollment_classroom.left_at.to_date

        next unless between_dates(date, joined_at, left_at)

        student_id = enrollment_classroom.student_enrollment.student_id
        student_enrollment_id = enrollment_classroom.student_enrollment.id
        students_hashes[student_id] ||= {}
        students_hashes[student_id][date] = student_enrollment_id
      end
    end
    students_hashes
  end

  private

  def between_dates(date, start_date, end_date)
    return false if start_date.nil? || date.nil?

    return date >= start_date if end_date.nil?

    date >= start_date && date < end_date
  end
end
