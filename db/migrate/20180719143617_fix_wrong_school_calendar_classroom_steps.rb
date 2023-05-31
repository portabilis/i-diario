class FixWrongSchoolCalendarClassroomSteps < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DELETE FROM descriptive_exams
      WHERE NOT EXISTS(
        SELECT 1
          FROM descriptive_exam_students AS des
        WHERE des.descriptive_exam_id = descriptive_exams.id
      );

      UPDATE descriptive_exams
          SET school_calendar_classroom_step_id = (
          SELECT MAX(sccsa.id)
              FROM school_calendar_classrooms AS scca
              JOIN school_calendar_classroom_steps AS sccsa
                ON sccsa.school_calendar_classroom_id = scca.id
            WHERE scca.classroom_id = descriptive_exams.classroom_id
              AND sccsa.start_at BETWEEN sccs.start_at AND sccs.end_at
              AND sccsa.end_at BETWEEN sccs.start_at AND sccs.end_at
        )
        FROM school_calendar_classroom_steps AS sccs
        JOIN school_calendar_classrooms AS scc
          ON scc.id = sccs.school_calendar_classroom_id
        WHERE sccs.id = descriptive_exams.school_calendar_classroom_step_id
          AND scc.classroom_id <> descriptive_exams.classroom_id;

      DELETE FROM conceptual_exams
      WHERE NOT EXISTS(
        SELECT 1
          FROM conceptual_exam_values AS cev
        WHERE cev.conceptual_exam_id = conceptual_exams.id
      );

      UPDATE conceptual_exams
          SET school_calendar_classroom_step_id = (
          SELECT MAX(sccsa.id)
              FROM school_calendar_classrooms AS scca
              JOIN school_calendar_classroom_steps AS sccsa
                ON sccsa.school_calendar_classroom_id = scca.id
            WHERE scca.classroom_id = conceptual_exams.classroom_id
              AND conceptual_exams.recorded_at BETWEEN sccsa.start_at AND sccsa.end_at
        )
        FROM school_calendar_classroom_steps AS sccs
        JOIN school_calendar_classrooms AS scc
          ON scc.id = sccs.school_calendar_classroom_id
        WHERE sccs.id = conceptual_exams.school_calendar_classroom_step_id
          AND scc.classroom_id <> conceptual_exams.classroom_id;

      UPDATE school_term_recovery_diary_records
          SET school_calendar_classroom_step_id = (
          SELECT MAX(sccsa.id)
              FROM school_calendar_classrooms AS scca
              JOIN school_calendar_classroom_steps AS sccsa
                ON sccsa.school_calendar_classroom_id = scca.id
            WHERE scca.classroom_id = rdr.classroom_id
              AND rdr.recorded_at BETWEEN sccsa.start_at AND sccsa.end_at
        )
        FROM recovery_diary_records AS rdr,
              school_calendar_classroom_steps AS sccs,
              school_calendar_classrooms AS scc
        WHERE rdr.id = school_term_recovery_diary_records.recovery_diary_record_id
          AND scc.classroom_id <> rdr.classroom_id
          AND sccs.id = school_term_recovery_diary_records.school_calendar_classroom_step_id
          AND scc.id = sccs.school_calendar_classroom_id;
    SQL
  end
end
