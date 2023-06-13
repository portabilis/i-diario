class PopulateAbsenceJustificationUserIdField < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DO $$DECLARE
        _absence_justification RECORD;
        _user_id INTEGER;
      BEGIN
        FOR _absence_justification IN (
          SELECT id, teacher_id
            FROM absence_justifications
        )LOOP
          SELECT id
            FROM users
           WHERE users.teacher_id = _absence_justification.teacher_id
            INTO _user_id;

            UPDATE absence_justifications
               SET user_id = _user_id
             WHERE id = _absence_justification.id;
        END LOOP;
      END$$;
    SQL
  end
end
