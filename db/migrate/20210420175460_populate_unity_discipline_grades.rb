class PopulateUnityDisciplineGrades < ActiveRecord::Migration
  def change
    execute <<-SQL
      DO $$
        DECLARE tdc RECORD;
        DECLARE classroom RECORD;
      BEGIN
        FOR tdc IN (
          SELECT DISTINCT
                 teacher_discipline_classrooms.classroom_id AS classroom_id,
                 teacher_discipline_classrooms.discipline_id AS discipline_id
            FROM teacher_discipline_classrooms
        )
        LOOP
          SELECT classrooms.grade_id,
                 classrooms.unity_id,
                 classrooms.year
            INTO classroom
            FROM classrooms
           WHERE classrooms.id = tdc.classroom_id;

          INSERT INTO unity_discipline_grades (
            unity_id,
            discipline_id,
            grade_id,
            year,
            created_at,
            updated_at
          ) VALUES (
            classroom.unity_id,
            tdc.discipline_id,
            classroom.grade_id,
            classroom.year,
            NOW(),
            NOW()
          );
        END LOOP;
      END$$;
    SQL
  end
end
