class MigrateAbsenceJustificationsDisciplines < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DO $$DECLARE
        absence_justification RECORD;
      BEGIN
        FOR absence_justification IN (
          SELECT id, discipline_id
            FROM absence_justifications
        ) LOOP
          IF absence_justification.discipline_id IS NOT NULL THEN
            INSERT
              INTO absence_justifications_disciplines (
                absence_justification_id,
                discipline_id
              )
            VALUES (
              absence_justification.id,
              absence_justification.discipline_id
            );
          END IF;
        END LOOP;
      END$$
    SQL
  end
end
