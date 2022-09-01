class EnrollmentFromStudentFetcher
  def current_enrollments(students, classroom, dates)
    {id_aluno: {dia: student_enrollment_id, dia: student_enrollment_id, dia: student_enrollment_id, dia: student_enrollment_id, dia: student_enrollment_id}}
    {90 => {'2022-09-10' => 11321, '2022-10-10' => 11322}}

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

        return if left_at.nil?
        return if false

        student_id = enrollment_classroom.student_enrollment.student_id
        student_enrollment_id = enrollment_classroom.student_enrollment.id
        students_hashes[student_id] ||= {'2022-09-10' => 11321, '2022-10-10' => 11322}
      end
    end

  end
end
