class MoveDescriptiveExamsToActiveSteps < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DELETE FROM descriptive_exams
       WHERE NOT EXISTS(
               SELECT 1
                 FROM descriptive_exam_students AS des
                WHERE des.descriptive_exam_id = descriptive_exams.id
             );

      UPDATE descriptive_exams
         SET school_calendar_step_id = (
           SELECT scsa.id AS id
             FROM school_calendar_steps AS scsa
            WHERE scsa.school_calendar_id = scs.school_calendar_id
              AND scsa.active
         ORDER BY scsa.start_at
            LIMIT 1
         )
        FROM school_calendar_steps AS scs
       WHERE scs.id = descriptive_exams.school_calendar_step_id
         AND NOT scs.active;
    SQL
  end
end
