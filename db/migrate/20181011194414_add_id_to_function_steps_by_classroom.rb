class AddIdToFunctionStepsByClassroom < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DROP FUNCTION steps_by_classroom(INT, INT);

      CREATE OR REPLACE FUNCTION steps_by_classroom(
        l_school_calendar_id INT,
        l_classroom_id INT
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
          SELECT ROW_NUMBER() OVER(ORDER BY scs.start_at) AS step_number,
                 scs.id AS step_id,
                 scs.start_at AS start_at,
                 scs.end_at AS end_at,
                 scs.start_date_for_posting AS start_date_for_posting,
                 scs.end_date_for_posting AS end_date_for_posting,
                 scs.created_at AS created_at,
                 scs.updated_at AS updated_at,
                 'general' AS type
            FROM school_calendars AS sc
            JOIN school_calendar_steps AS scs
              ON scs.school_calendar_id = sc.id
           WHERE sc.id = l_school_calendar_id
             AND scs.active
             AND NOT EXISTS(
                   SELECT 1
                     FROM school_calendar_classrooms AS scc
                    WHERE scc.school_calendar_id = sc.id
                      AND scc.classroom_id = l_classroom_id
                 )
          UNION ALL
          SELECT ROW_NUMBER() OVER(ORDER BY sccs.start_at) AS step_number,
                 sccs.id AS step_id,
                 sccs.start_at AS start_at,
                 sccs.end_at AS end_at,
                 sccs.start_date_for_posting AS start_date_for_posting,
                 sccs.end_date_for_posting AS end_date_for_posting,
                 sccs.created_at AS created_at,
                 sccs.updated_at AS updated_at,
                 'classroom' AS type
            FROM school_calendars AS sc
            JOIN school_calendar_classrooms AS scc
              ON scc.school_calendar_id = sc.id
            JOIN school_calendar_classroom_steps AS sccs
              ON sccs.school_calendar_classroom_id = scc.id
           WHERE sc.id = l_school_calendar_id
             AND scc.classroom_id = l_classroom_id
             AND sccs.active
        ORDER BY start_at
        );

        RETURN;
      END; $$
      LANGUAGE 'plpgsql';
    SQL
  end
end
