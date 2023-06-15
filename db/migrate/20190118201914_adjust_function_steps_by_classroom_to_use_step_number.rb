class AdjustFunctionStepsByClassroomToUseStepNumber < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DROP FUNCTION steps_by_classroom(INT);

      CREATE OR REPLACE FUNCTION steps_by_classroom(
        _classroom_id INT
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
      DECLARE
        _school_calendar_id INT;
      BEGIN
        SELECT school_calendars.id
          INTO _school_calendar_id
          FROM classrooms
          JOIN school_calendars
            ON school_calendars.unity_id = classrooms.unity_id
           AND school_calendars.year = classrooms.year
         WHERE classrooms.id = _classroom_id;

        RETURN QUERY (
          SELECT school_calendar_steps.step_number AS step_number,
                 school_calendar_steps.id AS step_id,
                 school_calendar_steps.start_at AS start_at,
                 school_calendar_steps.end_at AS end_at,
                 school_calendar_steps.start_date_for_posting AS start_date_for_posting,
                 school_calendar_steps.end_date_for_posting AS end_date_for_posting,
                 school_calendar_steps.created_at AS created_at,
                 school_calendar_steps.updated_at AS updated_at,
                 'general' AS type
            FROM school_calendar_steps
           WHERE school_calendar_steps.school_calendar_id = _school_calendar_id
             AND NOT EXISTS(
                   SELECT 1
                     FROM school_calendar_classrooms
                    WHERE school_calendar_classrooms.school_calendar_id = school_calendar_steps.school_calendar_id
                      AND school_calendar_classrooms.classroom_id = _classroom_id
                 )
          UNION ALL
          SELECT school_calendar_classroom_steps.step_number AS step_number,
                 school_calendar_classroom_steps.id AS step_id,
                 school_calendar_classroom_steps.start_at AS start_at,
                 school_calendar_classroom_steps.end_at AS end_at,
                 school_calendar_classroom_steps.start_date_for_posting AS start_date_for_posting,
                 school_calendar_classroom_steps.end_date_for_posting AS end_date_for_posting,
                 school_calendar_classroom_steps.created_at AS created_at,
                 school_calendar_classroom_steps.updated_at AS updated_at,
                 'classroom' AS type
            FROM school_calendar_classrooms
            JOIN school_calendar_classroom_steps
              ON school_calendar_classroom_steps.school_calendar_classroom_id = school_calendar_classrooms.id
           WHERE school_calendar_classrooms.school_calendar_id = _school_calendar_id
             AND school_calendar_classrooms.classroom_id = _classroom_id
        ORDER BY start_at
        );

        RETURN;
      END; $$
      LANGUAGE 'plpgsql';
    SQL
  end
end
