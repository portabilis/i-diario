class PopulateFieldOwnerTeacherId < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DO $$
        DECLARE _daily_frequency RECORD;
        DECLARE _user_id INTEGER;
        DECLARE _teacher_id INTEGER;
      BEGIN
        FOR _daily_frequency IN (
          SELECT id,
                 classroom_id,
                 discipline_id
            FROM daily_frequencies
           WHERE owner_teacher_id IS NULL
             AND EXTRACT(year FROM frequency_date) = 2020
        ) LOOP
            SELECT user_id
              INTO _user_id
              FROM audits
             WHERE auditable_type = 'DailyFrequency'
               AND action = 'create'
               AND auditable_id = _daily_frequency.id;

            IF _user_id IS NOT NULL THEN
              IF _user_id = 1 THEN
                IF _daily_frequency.discipline_id IS NOT NULL THEN
                  SELECT teacher_id
                    INTO _teacher_id
                    FROM teacher_discipline_classrooms
                   WHERE year = 2020
                     AND classroom_id = _daily_frequency.classroom_id
                     AND discipline_id = _daily_frequency.discipline_id;
                END IF;
              ELSE
                SELECT teacher_id
                  INTO _teacher_id
                  FROM users
                 WHERE id = _user_id;
              END IF;

              IF _teacher_id IS NOT NULL THEN
                UPDATE daily_frequencies
                   SET owner_teacher_id = _teacher_id
                 WHERE id = _daily_frequency.id;
              END IF;
            END IF;
        END LOOP;
      END$$;
    SQL
  end
end
