class AddFilterConditionToDailyNoteStatusesView < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DROP VIEW daily_note_statuses;
    SQL

    change_column(:daily_note_students, :active, :boolean, null: :false, default: :true)

    execute <<-SQL
      CREATE OR REPLACE VIEW daily_note_statuses AS
        SELECT outer_daily_notes.id AS daily_note_id,
          CASE
            WHEN (
              EXISTS (
                SELECT daily_notes.id
                  FROM daily_notes
                  JOIN daily_note_students ON (
                    daily_notes.id = daily_note_students.daily_note_id
                  )
                  JOIN avaliations ON (
                    daily_notes.avaliation_id = avaliations.id
                  )
                 WHERE daily_note_students.note IS NULL
                   AND daily_note_students.active = true
                   AND NOT (
                     EXISTS (
                       SELECT 1
                         FROM avaliation_exemptions
                        WHERE avaliation_exemptions.avaliation_id = daily_notes.avaliation_id
                          AND avaliation_exemptions.student_id = daily_note_students.student_id
                     )
                   )
                   AND (
                     EXISTS (
                       SELECT 1
                         FROM student_enrollment_classrooms
                         JOIN student_enrollments ON (
                           student_enrollment_classrooms.student_enrollment_id = student_enrollments.id
                         )
                          AND student_enrollments.student_id = daily_note_students.student_id
                          AND student_enrollment_classrooms.classroom_id = avaliations.classroom_id
                          AND student_enrollment_classrooms.left_at = ''
                     )
                   )
                 AND daily_notes.id = outer_daily_notes.id
              )
            )
            THEN
              'incomplete'::text
            ELSE
              'complete'::text
          END AS status
        FROM daily_notes outer_daily_notes;
    SQL
  end
end
