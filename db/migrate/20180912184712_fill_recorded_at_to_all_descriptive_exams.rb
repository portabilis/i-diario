class FillRecordedAtToAllDescriptiveExams < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE descriptive_exams
         SET recorded_at = scs.end_at
        FROM school_calendar_steps AS scs
       WHERE scs.id = descriptive_exams.school_calendar_step_id;

      UPDATE descriptive_exams
         SET recorded_at = sccs.end_at
        FROM school_calendar_classroom_steps AS sccs
        JOIN school_calendar_classrooms AS scc
          ON scc.id = sccs.school_calendar_classroom_id
       WHERE sccs.id = descriptive_exams.school_calendar_classroom_step_id
         AND scc.classroom_id = descriptive_exams.classroom_id;

      UPDATE descriptive_exams
         SET recorded_at = created_at
       WHERE recorded_at IS NULL;
    SQL
  end
end
