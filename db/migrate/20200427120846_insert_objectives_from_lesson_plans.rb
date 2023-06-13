class InsertObjectivesFromLessonPlans < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DO $$
        DECLARE _objective_id INT;
        DECLARE lesson_plan record;
        DECLARE objectives_list record;
      BEGIN
        FOR lesson_plan IN (
          SELECT lesson_plans.id AS id,
                 lesson_plans.objectives AS objectives
            FROM lesson_plans
           WHERE COALESCE(lesson_plans.objectives, '') <> ''
        )
        LOOP
          FOR objectives_list IN (
            SELECT objective
              FROM regexp_split_to_table(lesson_plan.objectives, '\r\n') AS objective
            WHERE objective <> ''
          )
          LOOP
            INSERT INTO objectives(
              description,
              created_at,
              updated_at
            )
            VALUES(
              objectives_list.objective,
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
        END LOOP;
      END$$;
    SQL
  end
end
