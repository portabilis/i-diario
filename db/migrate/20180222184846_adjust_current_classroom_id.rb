class AdjustCurrentClassroomId < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE users
         SET current_classroom_id = NULL,
             current_discipline_id = NULL
        FROM classrooms AS c
  INNER JOIN school_calendars AS sc
          ON sc.unity_id = c.unity_id
  INNER JOIN school_calendar_steps AS scs
          ON scs.school_calendar_id = sc.id
       WHERE c.id = users.current_classroom_id
         AND now() BETWEEN scs.start_at AND scs.end_at
         AND c.year <> sc.year
         AND NOT EXISTS(
              SELECT 1
                FROM school_calendar_classrooms AS scc
          INNER JOIN school_calendar_classroom_steps AS sccs
                  ON sccs.school_calendar_classroom_id = scc.id
          INNER JOIN school_calendars AS sc
                  ON sc.id = scc.school_calendar_id
               WHERE c.unity_id = sc.unity_id
                 AND scc.classroom_id = current_classroom_id
             );

      UPDATE users
         SET current_classroom_id = NULL,
             current_discipline_id = NULL
        FROM classrooms AS c
       WHERE c.id = users.current_classroom_id
         AND EXISTS(
              SELECT 1
                FROM school_calendar_classrooms AS scc
          INNER JOIN school_calendar_classroom_steps AS sccs
                  ON sccs.school_calendar_classroom_id = scc.id
          INNER JOIN school_calendars AS sc
                  ON sc.id = scc.school_calendar_id
               WHERE c.unity_id = sc.unity_id
                 AND scc.classroom_id = current_classroom_id
             )
         AND NOT EXISTS(
              SELECT 1
                FROM school_calendar_classrooms AS scc
          INNER JOIN school_calendar_classroom_steps AS sccs
                  ON sccs.school_calendar_classroom_id = scc.id
          INNER JOIN school_calendars AS sc
                  ON sc.id = scc.school_calendar_id
               WHERE c.unity_id = sc.unity_id
                 AND scc.classroom_id = current_classroom_id
                 AND now() BETWEEN sccs.start_at AND sccs.end_at
             );
    SQL
  end
end
