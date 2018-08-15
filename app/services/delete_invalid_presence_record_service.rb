class DeleteInvalidPresenceRecordService
  def initialize(student_enrollment_classroom)
    @student_enrollment_classroom = student_enrollment_classroom
  end

  def run!
    student_enrollment_classrooms = StudentEnrollmentClassroom.by_classroom(@student_enrollment_classroom.classroom_id)
                                                              .by_student_enrollment(@student_enrollment_classroom.student_enrollment_id)

    daily_frequency_students = DailyFrequencyStudent.by_classroom_id(@student_enrollment_classroom.classroom_id)
                                                    .by_student_id(@student_enrollment_classroom.student_enrollment.student_id)

    daily_frequency_students.each do |daily_frequency_student|
      daily_frequency_student.destroy unless student_enrollment_classrooms.by_date(daily_frequency_student.frequency_date).exists?
    end
  end
end
