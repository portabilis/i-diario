class AdjustWrongSchoolCalendarInDailyFrequencies < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DO $$DECLARE
        daily_frequency record;
      BEGIN
        FOR daily_frequency IN (
          SELECT *
            FROM daily_frequencies
           WHERE NOT EXISTS(
                   SELECT 1
                     FROM school_calendars
                    WHERE school_calendars.id = daily_frequencies.school_calendar_id
                      AND school_calendars.unity_id = daily_frequencies.unity_id
                      AND school_calendars.year = EXTRACT(YEAR FROM daily_frequencies.frequency_date)
                 )
        ) LOOP
          IF EXISTS(
            SELECT 1
              FROM daily_frequencies
             WHERE daily_frequencies.id <> daily_frequency.id
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
               SET school_calendar_id = (
                 SELECT school_calendars.id
                   FROM school_calendars
                  WHERE school_calendars.unity_id = daily_frequency.unity_id
                    AND school_calendars.year = EXTRACT(YEAR FROM daily_frequency.frequency_date)
               )
            WHERE id = daily_frequency.id;
          END IF;
        END LOOP;
      END$$;
    SQL
  end
end
