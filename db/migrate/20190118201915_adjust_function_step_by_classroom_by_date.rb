class AdjustFunctionStepByClassroomByDate < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DROP FUNCTION step_by_classroom(INT, DATE);

      CREATE OR REPLACE FUNCTION step_by_classroom(
        _classroom_id INT,
        _recorded_at DATE
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
           WHERE _recorded_at BETWEEN steps.start_at AND steps.end_at
           LIMIT 1
        );

        RETURN;
      END; $$
      LANGUAGE 'plpgsql';
    SQL
  end
end
