class InsertObjectivesFromTeachingPlans < ActiveRecord::Migration
  def change
    execute <<-SQL
      DO $$
        DECLARE _objective_id INT;
        DECLARE teaching_plan record;
      BEGIN
        FOR teaching_plan IN (
          SELECT teaching_plans.id AS id,
                 teaching_plans.objectives AS objectives
            FROM teaching_plans
           WHERE COALESCE(teaching_plans.objectives, '') <> ''
        )
        LOOP
          INSERT INTO objectives(
            description,
            created_at,
            updated_at
          )
          VALUES(
            teaching_plan.objectives,
            NOW(),
            NOW()
          )
          RETURNING id INTO _objective_id;

          INSERT INTO objectives_teaching_plans(
            objective_id,
            teaching_plan_id,
            created_at,
            updated_at
          )
          VALUES(
            _objective_id,
            teaching_plan.id,
            NOW(),
            NOW()
          );
        END LOOP;
      END$$;
    SQL
  end
end
