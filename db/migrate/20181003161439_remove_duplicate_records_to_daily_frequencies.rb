class RemoveDuplicateRecordsToDailyFrequencies < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DO $$DECLARE
        daily_frequency record;
      BEGIN
        FOR daily_frequency IN (
          SELECT daily_frequencies.*,
                 classrooms.unity_id AS correct_unity_id
            FROM daily_frequencies
            JOIN classrooms
              ON classrooms.id = daily_frequencies.classroom_id
           WHERE daily_frequencies.unity_id <> classrooms.unity_id
        ) LOOP
          IF EXISTS(
            SELECT 1
              FROM daily_frequencies
             WHERE daily_frequencies.unity_id = daily_frequency.correct_unity_id
               AND daily_frequencies.classroom_id = daily_frequency.classroom_id
               AND daily_frequencies.frequency_date = daily_frequency.frequency_date
               AND COALESCE(daily_frequencies.discipline_id, 0) = COALESCE(daily_frequency.discipline_id, 0)
               AND COALESCE(daily_frequencies.class_number, 0) = COALESCE(daily_frequency.class_number, 0)
          ) THEN
            DELETE
              FROM daily_frequency_students
             WHERE daily_frequency_id = daily_frequency.id;

            DELETE
              FROM daily_frequencies
             WHERE id = daily_frequency.id;
          ELSE
            UPDATE daily_frequencies
               SET unity_id = daily_frequency.correct_unity_id,
                   school_calendar_id = (
                     SELECT school_calendars.id
                       FROM school_calendars
                      WHERE school_calendars.unity_id = daily_frequency.correct_unity_id
                        AND school_calendars.year = EXTRACT(YEAR FROM daily_frequency.frequency_date)
               )
             WHERE id = daily_frequency.id;
          END IF;
        END LOOP;
      END$$;
    SQL
  end
end
