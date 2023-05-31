class UpdateSchoolCalendarStepsStepNumber < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE school_calendar_steps
         SET step_number = (
           SELECT td_steps.step_number
             FROM school_calendar_steps AS scs,
          LATERAL (SELECT ROW_NUMBER() OVER(ORDER BY steps.start_at) AS step_number,
                          steps.id AS step_id
                     FROM school_calendar_steps AS steps
                    WHERE steps.school_calendar_id = scs.school_calendar_id
                  ) AS td_steps
            WHERE scs.id = school_calendar_steps.id
              AND scs.id = td_steps.step_id
         )
    SQL
  end
end
