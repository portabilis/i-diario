class FixDescriptiveExamsWithBothSteps < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE descriptive_exams
         SET school_calendar_step_id = NULL
       WHERE school_calendar_step_id IS NOT NULL
         AND school_calendar_classroom_step_id IS NOT NULL
         AND EXISTS(SELECT 1
                      FROM school_calendar_classrooms AS scc
                     WHERE scc.classroom_id = descriptive_exams.classroom_id
             );

      UPDATE descriptive_exams
         SET school_calendar_classroom_step_id = NULL
       WHERE school_calendar_step_id IS NOT NULL
         AND school_calendar_classroom_step_id IS NOT NULL
         AND NOT EXISTS(SELECT 1
                          FROM school_calendar_classrooms AS scc
                         WHERE scc.classroom_id = descriptive_exams.classroom_id
             );
    SQL
  end
end
