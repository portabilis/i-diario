class RemoveDuplicatedDailyFrequenciesAndAddUniqueIndexs < ActiveRecord::Migration
  def change
    execute <<-SQL
      CREATE OR REPLACE FUNCTION public.remove_duplicated_daily_frequencies_and_create_indexes() RETURNS void AS $BODY$
      DECLARE
        dailyFrequencyToKeep INTEGER;
        dailyFrequencyStToKeep INTEGER;
        cur RECORD;
      BEGIN

      FOR cur IN (select unity_id, classroom_id, frequency_date, discipline_id, class_number, school_calendar_id
        from daily_frequencies
        group by unity_id, classroom_id, frequency_date, discipline_id, class_number, school_calendar_id
        having count(id) > 1
      ) LOOP

        -- Irei manter o DailyFrequency que possui maior número de lançamentos
        -- e mais recente

        dailyFrequencyToKeep := 0;

        SELECT id into dailyFrequencyToKeep
        FROM daily_frequencies
        WHERE unity_id =  cur.unity_id
        and classroom_id =  cur.classroom_id
        AND frequency_date = cur.frequency_date
        AND COALESCE(discipline_id,0) =  COALESCE(cur.discipline_id,0)
        and COALESCE(class_number,0) =  COALESCE(cur.class_number,0)
        ORDER BY (SELECT COUNT(*)
        FROM daily_frequency_students
        WHERE daily_frequency_id = daily_frequencies.id
        ) desc, updated_at desc;

        If COALESCE(dailyFrequencyToKeep, 0) = 0 Then
          RAISE 'Alguma coisa deu errado';
        End if;

        DELETE FROM daily_frequency_students
        WHERE daily_frequency_id in (
          SELECT id FROM daily_frequencies
          WHERE unity_id = cur.unity_id
          and classroom_id = cur.classroom_id
          AND frequency_date = cur.frequency_date
          AND COALESCE(discipline_id,0) =  COALESCE(cur.discipline_id,0)
          and COALESCE(class_number,0) =  COALESCE(cur.class_number,0)
          AND id <> dailyFrequencyToKeep);

        DELETE FROM daily_frequencies
        WHERE unity_id =  cur.unity_id
        and classroom_id =  cur.classroom_id
        AND frequency_date = cur.frequency_date
        AND COALESCE(discipline_id,0) = COALESCE(cur.discipline_id,0)
        and COALESCE(class_number,0) = COALESCE(cur.class_number,0)
        and COALESCE(school_calendar_id,0) =  COALESCE(cur.school_calendar_id,0)
        AND id <> dailyFrequencyToKeep;


      END LOOP;


      FOR cur IN (
        SELECT daily_frequency_id, student_id
        FROM daily_frequency_students
        GROUP BY daily_frequency_id, student_id
        HAVING COUNT(*)>1
      ) LOOP
        dailyFrequencyStToKeep := 0;

        SELECT id INTO dailyFrequencyStToKeep
        FROM daily_frequency_students
        WHERE daily_frequency_id = cur.daily_frequency_id
        AND student_id = cur.student_id
        ORDER BY updated_at DESC
        LIMIT 1;

        If COALESCE(dailyFrequencyStToKeep,0)=0 Then
          RAISE 'Algo deu errado';
        End if;

        DELETE FROM daily_frequency_students
        WHERE id <> dailyFrequencyStToKeep
        AND daily_frequency_id = cur.daily_frequency_id
        AND student_id = cur.student_id;

      END LOOP;

      CREATE UNIQUE INDEX daily_frequency_students_daily_frequency_id_student_id_idx
      ON daily_frequency_students (daily_frequency_id, student_id);

      CREATE UNIQUE INDEX daily_frequencies_unique_idx
      ON daily_frequencies (unity_id, classroom_id, frequency_date, discipline_id, class_number);


      END;$BODY$ LANGUAGE plpgsql VOLATILE;

      SELECT public.remove_duplicated_daily_frequencies_and_create_indexes();

      DROP FUNCTION public.remove_duplicated_daily_frequencies_and_create_indexes();

    SQL
  end
end
