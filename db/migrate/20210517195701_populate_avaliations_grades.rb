class PopulateAvaliationsGrades < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DO $$
        DECLARE avaliation RECORD;
        DECLARE grade_id INTEGER;
      BEGIN
        FOR avaliation IN (
          SELECT avaliations.id AS id,
                 avaliations.classroom_id AS classroom_id
            FROM avaliations
        )
        LOOP
          SELECT classrooms.grade_id
            INTO grade_id
            FROM classrooms
           WHERE id = avaliation.classroom_id;

          INSERT INTO avaliations_grades (
            avaliation_id,
            grade_id,
            created_at,
            updated_at
          ) VALUES (
            avaliation.id,
            grade_id,
            NOW(),
            NOW()
          );
        END LOOP;
      END$$;
    SQL
  end
end
