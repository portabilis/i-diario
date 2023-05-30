class RemoveDuplicatedDailyFrequencies < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DO $$
        DECLARE _daily_frequency RECORD;
        DECLARE _repeated_daily_frequency_ids INTEGER[];
      BEGIN
        FOR _daily_frequency IN (
          SELECT MAX(daily_frequencies.id) AS correct_id,
                 daily_frequencies.classroom_id AS classroom_id,
                 daily_frequencies.frequency_date AS frequency_date,
                 daily_frequencies.discipline_id AS discipline_id,
                 daily_frequencies.class_number AS class_number
            FROM daily_frequencies
            JOIN classrooms
              ON classrooms.id = daily_frequencies.classroom_id
             AND classrooms.discarded_at IS NULL
           WHERE (classrooms.period <> '4')
        GROUP BY daily_frequencies.classroom_id,
                 daily_frequencies.frequency_date,
                 daily_frequencies.discipline_id,
                 daily_frequencies.class_number
          HAVING COUNT(1) > 1
        ) LOOP
          _repeated_daily_frequency_ids := ARRAY[]::INTEGER[];
          _repeated_daily_frequency_ids := ARRAY(
            SELECT id
              FROM daily_frequencies
            WHERE classroom_id = _daily_frequency.classroom_id
              AND frequency_date = _daily_frequency.frequency_date
              AND COALESCE(discipline_id, 0) = COALESCE(_daily_frequency.discipline_id, 0)
              AND COALESCE(class_number, 0) = COALESCE(_daily_frequency.class_number, 0)
              AND daily_frequencies.id <> _daily_frequency.correct_id
          );

          DELETE FROM daily_frequency_students
           WHERE daily_frequency_id = ANY (_repeated_daily_frequency_ids);

          DELETE FROM daily_frequencies
           WHERE id = ANY ( _repeated_daily_frequency_ids);
        END LOOP;
      END$$;
    SQL
  end
end
