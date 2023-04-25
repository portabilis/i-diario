class PopulateSchoolCalendarDisciplineGrades < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DO $$
        DECLARE tdc RECORD;
        DECLARE school_calendar_id INTEGER;
      BEGIN
        FOR tdc IN (
          SELECT DISTINCT
                 teacher_discipline_classrooms.discipline_id AS discipline_id,
                 classrooms.grade_id AS grade_id,
                 classrooms.year AS year,
                 classrooms.unity_id AS unity_id
            FROM teacher_discipline_classrooms
            JOIN classrooms ON teacher_discipline_classrooms.classroom_id = classrooms.id
        )
        LOOP
          SELECT id
            INTO school_calendar_id
            FROM school_calendars
           WHERE year = tdc.year
             AND unity_id = tdc.unity_id;

          INSERT INTO school_calendar_discipline_grades (
            school_calendar_id,
            discipline_id,
            grade_id,
            created_at,
            updated_at
          ) VALUES (
            school_calendar_id,
            tdc.discipline_id,
            tdc.grade_id,
            NOW(),
            NOW()
          );
        END LOOP;
      END$$;
    SQL
  end
end
