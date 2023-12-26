class CreateFunctionCheckToKeepUniqueAbsenceJustificationsStudents < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      CREATE OR REPLACE FUNCTION check_absence_justification_student_is_unique(
        _student_id INT,
        _absence_justification_id INT,
        _id INT,
        _discarded_at TIMESTAMP
      )
        RETURNS BOOLEAN AS
      $$
      DECLARE
        _absence_justification RECORD;
      BEGIN
        IF _discarded_at IS NOT NULL THEN
          RETURN TRUE;
        END IF;
        FOR _absence_justification IN (
          SELECT absence_justifications.classroom_id AS classroom_id,
                 absence_justifications.school_calendar_id AS school_calendar_id,
                 absence_justifications.absence_date AS absence_date,
                 absence_justifications.absence_date_end AS absence_date_end,
                 absence_justifications_disciplines.discipline_id AS discipline_id
            FROM absence_justifications
            JOIN absence_justifications_students
              ON absence_justifications_students.absence_justification_id = absence_justifications.id
            JOIN absence_justifications_disciplines
              ON absence_justifications_disciplines.absence_justification_id = absence_justifications.id
           WHERE absence_justifications.id = _absence_justification_id
        ) LOOP
          IF EXISTS(
            SELECT 1
              FROM absence_justifications
              JOIN absence_justifications_students
                ON absence_justifications_students.absence_justification_id = absence_justifications.id
              JOIN absence_justifications_disciplines
                ON absence_justifications_disciplines.absence_justification_id = absence_justifications.id
             WHERE absence_justifications_students.student_id = _student_id
               AND absence_justifications.id <> _absence_justification_id
               AND absence_justifications.classroom_id = _absence_justification.classroom_id
               AND absence_justifications.school_calendar_id = _absence_justification.school_calendar_id
               AND absence_justifications_disciplines.discipline_id = _absence_justification.discipline_id
               AND (
                 (
                  absence_justifications.absence_date BETWEEN
                    _absence_justification.absence_date AND _absence_justification.absence_date_end
                 ) OR
                 (
                  absence_justifications.absence_date_end BETWEEN
                    _absence_justification.absence_date AND _absence_justification.absence_date_end
                 )
              )
          ) THEN
            RETURN FALSE;
          END IF;
        END LOOP;
        RETURN TRUE;
      END
      $$ LANGUAGE plpgsql;
    SQL
  end
end
