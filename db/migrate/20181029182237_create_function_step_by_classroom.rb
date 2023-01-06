class CreateFunctionStepByClassroom < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      CREATE OR REPLACE FUNCTION step_by_classroom(
        l_classroom_id INT,
        l_recorded_at DATE
      )
      RETURNS TABLE (
        step_number BIGINT,
        step_id INT,
        start_at DATE,
        end_at DATE,
        start_date_for_posting DATE,
        end_date_for_posting DATE,
        created_at TIMESTAMP,
        updated_at TIMESTAMP,
        type TEXT
      ) AS $$
      BEGIN
        RETURN QUERY (
          SELECT *
            FROM steps_by_classroom(l_classroom_id) AS steps
           WHERE l_recorded_at BETWEEN steps.start_at AND steps.end_at
           LIMIT 1
        );

        RETURN;
      END; $$
      LANGUAGE 'plpgsql';
    SQL
  end
end
