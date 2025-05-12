class CreateFunctionStepByClassroomByStepNumber < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      CREATE OR REPLACE FUNCTION step_by_classroom(
        _classroom_id INT,
        _step_number INT
      )
      RETURNS TABLE (
        step_number INT,
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
            FROM steps_by_classroom(_classroom_id) AS steps
           WHERE steps.step_number = _step_number
           LIMIT 1
        );

        RETURN;
      END; $$
      LANGUAGE 'plpgsql';
    SQL
  end
end
