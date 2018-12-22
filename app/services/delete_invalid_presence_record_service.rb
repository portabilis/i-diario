class DeleteInvalidPresenceRecordService
  def initialize(student_id, classroom_id)
    @student_id = student_id
    @classroom_id = classroom_id
  end

  def run!
    daily_frequency_students_list = daily_frequency_students_list
    destroy_list_daily_frequency_students(daily_frequency_students_list)
  end

  def daily_frequency_students_list
    DailyFrequencyStudent.joins(:daily_frequency)
                         .by_classroom_id(@classroom_id)
                         .by_student_id(@student_id)
                         .where(<<-SQL
                            NOT EXISTS(
                              SELECT 1
                                FROM student_enrollments AS se
                                JOIN student_enrollment_classrooms AS sec
                                  ON sec.classroom_id = daily_frequencies.classroom_id
                                AND sec.student_enrollment_id = se.id
                                AND daily_frequencies.frequency_date >= CAST(sec.joined_at AS DATE)
                                AND (COALESCE(sec.left_at, '') = '' OR
                                      daily_frequencies.frequency_date < CAST(sec.left_at AS DATE))
                              WHERE se.student_id = #{@student_id}
                            )
                         SQL
                               )
  end

  def destroy_list_daily_frequency_students(daily_frequency_list)
    daily_frequency_list.destroy_all
  end
end
