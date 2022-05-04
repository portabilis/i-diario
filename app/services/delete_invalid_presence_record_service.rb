class DeleteInvalidPresenceRecordService
  def initialize(student_id, classroom_id)
    @student_id = student_id
    @classroom_id = classroom_id
  end

  def run!
    daily_frequency_students = DailyFrequencyStudent.joins(:daily_frequency)
                                                    .by_classroom_id(@classroom_id)
                                                    .by_student_id(@student_id)
                                                    .where(not_exists_a_valid_enrollment_sql)

    daily_frequency_students.destroy_all
  end

  private

  def not_exists_a_valid_enrollment_sql
    <<-SQL
      NOT EXISTS(
        SELECT 1
          FROM student_enrollments
          JOIN student_enrollment_classrooms
            ON student_enrollment_classrooms.student_enrollment_id = student_enrollments.id
          JOIN classrooms_grades
            ON classrooms_grades.classroom_id = daily_frequencies.classroom_id
           AND student_enrollment_classrooms.classrooms_grade_id = classrooms_grades.id
         WHERE student_enrollments.student_id = #{@student_id}
           AND daily_frequencies.frequency_date >= CAST(student_enrollment_classrooms.joined_at AS DATE)
           AND (
                 COALESCE(student_enrollment_classrooms.left_at, '') = '' OR
                 daily_frequencies.frequency_date < CAST(student_enrollment_classrooms.left_at AS DATE)
               )
      )
    SQL
  end
end
