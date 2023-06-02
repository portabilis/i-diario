class RemoveDuplicatedDailyFrequenciesAndAddUniqueIndexs < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      CREATE OR REPLACE FUNCTION public.remove_duplicated_daily_frequencies_and_create_indexes() RETURNS void AS $BODY$
      DECLARE
        dailyFrequencyToKeep INTEGER;
        dailyFrequencyStToKeep INTEGER;
        cur RECORD;
      BEGIN
        FOR cur IN (SELECT unity_id,
                           classroom_id,
                           frequency_date,
                           discipline_id,
                           class_number,
                           school_calendar_id
                    FROM daily_frequencies
                    GROUP BY unity_id, classroom_id, frequency_date, discipline_id, class_number, school_calendar_id
                    HAVING count(id) > 1)
        LOOP
          -- Irei manter o DailyFrequency que possui maior número de lançamentos
          -- e mais recente
          dailyFrequencyToKeep := 0;

          SELECT id INTO dailyFrequencyToKeep
          FROM daily_frequencies
          WHERE unity_id =  cur.unity_id AND
                classroom_id =  cur.classroom_id AND
                frequency_date = cur.frequency_date AND
                COALESCE(discipline_id,0) =  COALESCE(cur.discipline_id,0) AND
                COALESCE(class_number,0) =  COALESCE(cur.class_number,0)
          ORDER BY (SELECT COUNT(*)
                    FROM daily_frequency_students
                    WHERE daily_frequency_id = daily_frequencies.id ) desc, updated_at desc;

          IF COALESCE(dailyFrequencyToKeep, 0) = 0 THEN
            RAISE 'Alguma coisa deu errado';
          END IF;

          DELETE FROM daily_frequency_students
          WHERE daily_frequency_id IN ( SELECT id
                                        FROM daily_frequencies
                                        WHERE unity_id = cur.unity_id AND
                                              classroom_id = cur.classroom_id AND
                                              frequency_date = cur.frequency_date AND
                                              COALESCE(discipline_id,0) =  COALESCE(cur.discipline_id,0) AND
                                              COALESCE(class_number,0) =  COALESCE(cur.class_number,0) AND
                                              id <> dailyFrequencyToKeep);

          DELETE FROM daily_frequencies
          WHERE unity_id =  cur.unity_id AND
                classroom_id =  cur.classroom_id AND
                frequency_date = cur.frequency_date AND
                COALESCE(discipline_id,0) = COALESCE(cur.discipline_id,0) AND
                COALESCE(class_number,0) = COALESCE(cur.class_number,0) AND
                id <> dailyFrequencyToKeep;

        END LOOP;

        FOR cur IN ( SELECT daily_frequency_id, student_id
                     FROM daily_frequency_students
                     GROUP BY daily_frequency_id, student_id
                     HAVING COUNT(*)>1 )
        LOOP
          dailyFrequencyStToKeep := 0;

          SELECT id INTO dailyFrequencyStToKeep
          FROM daily_frequency_students
          WHERE daily_frequency_id = cur.daily_frequency_id AND
                student_id = cur.student_id
          ORDER BY updated_at DESC
          LIMIT 1;

          IF COALESCE(dailyFrequencyStToKeep,0)=0 THEN
            RAISE 'Algo deu errado';
          END IF;

          DELETE FROM daily_frequency_students
          WHERE id <> dailyFrequencyStToKeep AND
                daily_frequency_id = cur.daily_frequency_id AND
                student_id = cur.student_id;
        END LOOP;

        IF EXISTS ( SELECT 1
                    FROM pg_class
                    JOIN pg_namespace ON (pg_namespace.oid = pg_class.relnamespace)
                    WHERE pg_class.relname = 'daily_frequency_students_daily_frequency_id_student_id_idx' AND
                          pg_namespace.nspname = 'public' ) THEN
          DROP INDEX daily_frequency_students_daily_frequency_id_student_id_idx;
        END IF;

        CREATE UNIQUE INDEX daily_frequency_students_daily_frequency_id_student_id_idx ON
          daily_frequency_students (daily_frequency_id, student_id);

          IF EXISTS ( SELECT 1
                      FROM pg_class
                      JOIN pg_namespace ON (pg_namespace.oid = pg_class.relnamespace)
                      WHERE pg_class.relname = 'daily_frequencies_unique_idx' AND
                            pg_namespace.nspname = 'public' ) THEN
          DROP INDEX daily_frequencies_unique_idx;
        END IF;

        CREATE UNIQUE INDEX daily_frequencies_unique_idx ON
          daily_frequencies (unity_id, classroom_id, frequency_date, discipline_id, class_number, school_calendar_id);

      END;$BODY$ LANGUAGE plpgsql VOLATILE;

      SELECT public.remove_duplicated_daily_frequencies_and_create_indexes();

      DROP FUNCTION public.remove_duplicated_daily_frequencies_and_create_indexes();
    SQL
  end
end
