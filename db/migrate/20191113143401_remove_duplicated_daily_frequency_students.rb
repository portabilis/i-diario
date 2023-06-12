class RemoveDuplicatedDailyFrequencyStudents < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DO $$
        DECLARE daily_frequency_student record;
        DECLARE correct_daily_frequency_student_id INT;
        DECLARE daily_frequency_student_to_delete record;
      BEGIN
        FOR daily_frequency_student IN (
          SELECT daily_frequency_id,
                 student_id
            FROM daily_frequency_students
           WHERE discarded_at IS NULL
        GROUP BY daily_frequency_id,
                 student_id
          HAVING COUNT(1) > 1
        )
        LOOP
          SELECT daily_frequency_students.id
            INTO correct_daily_frequency_student_id
            FROM daily_frequency_students
           WHERE daily_frequency_students.daily_frequency_id = daily_frequency_student.daily_frequency_id
             AND daily_frequency_students.student_id = daily_frequency_student.student_id
             AND daily_frequency_students.discarded_at IS NULL
        ORDER BY daily_frequency_students.active DESC
           LIMIT 1;

          FOR daily_frequency_student_to_delete IN (
            SELECT daily_frequency_students.id
              FROM daily_frequency_students
             WHERE daily_frequency_students.daily_frequency_id = daily_frequency_student.daily_frequency_id
               AND daily_frequency_students.student_id = daily_frequency_student.student_id
               AND daily_frequency_students.discarded_at IS NULL
               AND daily_frequency_students.id <> correct_daily_frequency_student_id
          )
          LOOP
            DELETE FROM daily_frequency_students WHERE id = daily_frequency_student_to_delete.id;
          END LOOP;
        END LOOP;
      END$$;
    SQL
  end
end
