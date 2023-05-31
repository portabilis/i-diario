class PopulateClassroomsGrades < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DO $$
        DECLARE classroom RECORD;
      BEGIN
        FOR classroom IN (
          SELECT classrooms.id AS id,
                 classrooms.grade_id AS grade_id,
                 classrooms.exam_rule_id AS exam_rule_id
            FROM classrooms
        )
        LOOP
          INSERT INTO classrooms_grades (
            classroom_id,
            grade_id,
            exam_rule_id,
            created_at,
            updated_at
          ) VALUES (
            classroom.id,
            classroom.grade_id,
            classroom.exam_rule_id,
            NOW(),
            NOW()
          );
        END LOOP;
      END$$;
    SQL
  end
end
