class DeleteInvalidPresenceRecordService
  def initialize(student_enrollment_classroom)
    @student_enrollment_classroom = student_enrollment_classroom
  end

  def run!
    daily_frequency_students =
      DailyFrequencyStudent.joins(:daily_frequency).joins(
        <<-SQL
          LEFT JOIN student_enrollment_classrooms AS sec
                 ON sec.classroom_id = daily_frequencies.classroom_id
                AND sec.student_enrollment_id = #{@student_enrollment_classroom.student_enrollment_id}
                AND daily_frequencies.frequency_date >= CAST(sec.joined_at AS DATE)
                AND (COALESCE(sec.left_at, '') = '' OR
                     daily_frequencies.frequency_date < CAST(sec.left_at AS DATE))
        SQL
      )
      .by_classroom_id(@student_enrollment_classroom.classroom_id)
      .by_student_id(@student_enrollment_classroom.student_enrollment.student_id)
      .where('sec.id IS NULL')

    daily_frequency_students.each do |daily_frequency_student|
      daily_frequency_student.destroy
    end
  end
end
