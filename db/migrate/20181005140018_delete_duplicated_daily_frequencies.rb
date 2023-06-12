class DeleteDuplicatedDailyFrequencies < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DO $$DECLARE
        daily_frequency record;
        daily_frequency_student record;
      BEGIN
        FOR daily_frequency IN (
          SELECT MAX(daily_frequencies.id) AS last_id,
                 daily_frequencies.classroom_id,
                 daily_frequencies.frequency_date
            FROM daily_frequencies
           WHERE daily_frequencies.discipline_id IS NULL
             AND daily_frequencies.class_number IS NULL
        GROUP BY daily_frequencies.classroom_id,
                 daily_frequencies.frequency_date
          HAVING COUNT(1) > 1
        ) LOOP
          FOR daily_frequency_student IN (
            SELECT daily_frequency_students.student_id
              FROM daily_frequencies
              JOIN daily_frequency_students
                ON daily_frequency_students.daily_frequency_id = daily_frequencies.id
             WHERE daily_frequencies.classroom_id = daily_frequency.classroom_id
               AND daily_frequencies.frequency_date = daily_frequency.frequency_date
               AND daily_frequencies.discipline_id IS NULL
               AND daily_frequencies.class_number IS NULL
               AND NOT daily_frequency_students.present
          ) LOOP
            UPDATE daily_frequency_students
               SET present = FALSE
             WHERE daily_frequency_id = daily_frequency.last_id
               AND student_id = daily_frequency_student.student_id;
          END LOOP;

          DELETE
            FROM daily_frequency_students
           USING daily_frequencies
           WHERE daily_frequency_students.daily_frequency_id = daily_frequencies.id
             AND daily_frequencies.classroom_id = daily_frequency.classroom_id
             AND daily_frequencies.frequency_date = daily_frequency.frequency_date
             AND daily_frequencies.discipline_id IS NULL
             AND daily_frequencies.class_number IS NULL
             AND daily_frequencies.id <> daily_frequency.last_id;

          DELETE
            FROM daily_frequencies
           WHERE daily_frequencies.classroom_id = daily_frequency.classroom_id
             AND daily_frequencies.frequency_date = daily_frequency.frequency_date
             AND daily_frequencies.discipline_id IS NULL
             AND daily_frequencies.class_number IS NULL
             AND daily_frequencies.id <> daily_frequency.last_id;
        END LOOP;
      END$$;
    SQL
  end
end
