class InsertObjectivesFromLessonPlans < ActiveRecord::Migration
  def change
    execute <<-SQL
      DO $$
        DECLARE _objective_id INT;
        DECLARE lesson_plan record;
      BEGIN
        FOR lesson_plan IN (
          SELECT lesson_plans.id AS id,
                 lesson_plans.objectives AS objectives
            FROM lesson_plans
           WHERE COALESCE(lesson_plans.objectives, '') <> ''
        )
        LOOP
          INSERT INTO objectives(
            description,
            created_at,
            updated_at
          )
          VALUES(
            lesson_plan.objectives,
            NOW(),
            NOW()
          )
          RETURNING id INTO _objective_id;

          INSERT INTO objectives_lesson_plans(
            objective_id,
            lesson_plan_id,
            created_at,
            updated_at
          )
          VALUES(
            _objective_id,
            lesson_plan.id,
            NOW(),
            NOW()
          );
        END LOOP;
      END$$;
    SQL
  end
end
