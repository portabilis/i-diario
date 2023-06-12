class MoveDescriptiveExamsInInactiveStepsToActiveSteps < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE descriptive_exams
         SET school_calendar_classroom_step_id = (
           SELECT sccsa.id AS id
             FROM school_calendar_classroom_steps AS sccsa
            WHERE sccsa.school_calendar_classroom_id = sccs.school_calendar_classroom_id
              AND sccsa.active
              AND descriptive_exams.created_at BETWEEN sccsa.start_at AND sccsa.end_at
            LIMIT 1
         )
        FROM school_calendar_classroom_steps AS sccs
       WHERE sccs.id = descriptive_exams.school_calendar_classroom_step_id
         AND NOT sccs.active;

      UPDATE descriptive_exams
         SET school_calendar_step_id = (
           SELECT scsa.id AS id
             FROM school_calendar_steps AS scsa
            WHERE scsa.school_calendar_id = scs.school_calendar_id
              AND scsa.active
              AND descriptive_exams.created_at BETWEEN scsa.start_at AND scsa.end_at
            LIMIT 1
         )
        FROM school_calendar_steps AS scs
       WHERE scs.id = descriptive_exams.school_calendar_step_id
         AND NOT scs.active;
    SQL
  end
end
