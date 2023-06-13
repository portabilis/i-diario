class FixRecordsWithBothSteps < ActiveRecord::Migration[4.2]
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

      UPDATE conceptual_exams
         SET school_calendar_step_id = NULL
       WHERE school_calendar_step_id IS NOT NULL
         AND school_calendar_classroom_step_id IS NOT NULL
         AND EXISTS(SELECT 1
                      FROM school_calendar_classrooms AS scc
                     WHERE scc.classroom_id = conceptual_exams.classroom_id
             );

      UPDATE conceptual_exams
         SET school_calendar_classroom_step_id = NULL
       WHERE school_calendar_step_id IS NOT NULL
         AND school_calendar_classroom_step_id IS NOT NULL
         AND NOT EXISTS(SELECT 1
                          FROM school_calendar_classrooms AS scc
                         WHERE scc.classroom_id = conceptual_exams.classroom_id
             );

      UPDATE transfer_notes
         SET school_calendar_step_id = NULL
       WHERE school_calendar_step_id IS NOT NULL
         AND school_calendar_classroom_step_id IS NOT NULL
         AND EXISTS(SELECT 1
                      FROM school_calendar_classrooms AS scc
                     WHERE scc.classroom_id = transfer_notes.classroom_id
             );

      UPDATE transfer_notes
         SET school_calendar_classroom_step_id = NULL
       WHERE school_calendar_step_id IS NOT NULL
         AND school_calendar_classroom_step_id IS NOT NULL
         AND NOT EXISTS(SELECT 1
                          FROM school_calendar_classrooms AS scc
                         WHERE scc.classroom_id = transfer_notes.classroom_id
             );

      UPDATE school_term_recovery_diary_records
         SET school_calendar_step_id = NULL
        FROM recovery_diary_records AS rdr
       WHERE rdr.id = school_term_recovery_diary_records.recovery_diary_record_id
         AND school_calendar_step_id IS NOT NULL
         AND school_calendar_classroom_step_id IS NOT NULL
         AND EXISTS(SELECT 1
                      FROM school_calendar_classrooms AS scc
                     WHERE scc.classroom_id = rdr.classroom_id
             );

      UPDATE school_term_recovery_diary_records
         SET school_calendar_classroom_step_id = NULL
        FROM recovery_diary_records AS rdr
       WHERE rdr.id = school_term_recovery_diary_records.recovery_diary_record_id
         AND school_calendar_step_id IS NOT NULL
         AND school_calendar_classroom_step_id IS NOT NULL
         AND NOT EXISTS(SELECT 1
                          FROM school_calendar_classrooms AS scc
                         WHERE scc.classroom_id = rdr.classroom_id
             );
    SQL
  end
end
