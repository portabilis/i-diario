class DeleteInactiveSteps < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DELETE
        FROM ieducar_api_exam_postings
       WHERE EXISTS(
               SELECT 1
                 FROM school_calendar_steps
                WHERE school_calendar_steps.id = ieducar_api_exam_postings.school_calendar_step_id
                  AND NOT school_calendar_steps.active
             )
          OR EXISTS(
               SELECT 1
                 FROM school_calendar_classroom_steps
                WHERE school_calendar_classroom_steps.id = ieducar_api_exam_postings.school_calendar_classroom_step_id
                  AND NOT school_calendar_classroom_steps.active
             );

      DELETE
        FROM school_calendar_steps
       WHERE NOT active;

      DELETE
        FROM school_calendar_classroom_steps
       WHERE NOT active;
    SQL
  end
end
