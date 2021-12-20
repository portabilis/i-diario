class StudentEnrollmentClassroomBusinesses
  def generate_sequence(student_enrollment, student_enrollment_classroom_record)
    Classroom.where(api_code: student_enrollment_classroom_record.turma_id)
    StudentEnrollmentClassroom.by_student(student_enrollment.student.id).pluck(:id, :classroom_id)
    
    StudentEnrollmentClassroom.
      by_student(student_enrollment.student.id).
      by_classroom(student_enrollment_classroom_record.turma_id).each do |student_enrollment_classroom|
      student_enrollment_classroom

    end

    student_enrollment_classroom_record

  end
end
