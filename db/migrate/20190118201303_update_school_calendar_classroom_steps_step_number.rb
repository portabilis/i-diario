class UpdateSchoolCalendarClassroomStepsStepNumber < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE school_calendar_classroom_steps
         SET step_number = (
           SELECT td_steps.step_number
             FROM school_calendar_classroom_steps AS sccs
             JOIN school_calendar_classrooms AS scc
               ON scc.id = sccs.school_calendar_classroom_id,
          LATERAL (SELECT ROW_NUMBER() OVER(ORDER BY steps.start_at) AS step_number,
                          steps.id AS step_id
                     FROM school_calendar_classroom_steps AS steps
                     JOIN school_calendar_classrooms AS classrooms
                       ON classrooms.id = steps.school_calendar_classroom_id
                    WHERE classrooms.school_calendar_id = scc.school_calendar_id
                      AND classrooms.classroom_id = scc.classroom_id
                  ) AS td_steps
            WHERE sccs.id = school_calendar_classroom_steps.id
              AND sccs.id = td_steps.step_id
         )
    SQL
  end
end
