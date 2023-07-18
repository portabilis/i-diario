class AdjustWrongClassroomIdInAvaliations < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DO $$
        DECLARE avaliation record;
        DECLARE correct_classroom_id INT;
      BEGIN
        FOR avaliation IN (
          SELECT audits.auditable_id AS id
            FROM audits
           WHERE auditable_type = 'Avaliation'
             AND action = 'update'
             AND audited_changes ilike '%classroom_id%'
        )
        LOOP
          SELECT SUBSTRING(audited_changes FROM 'classroom_id: ([0-9]*)\n')
            INTO correct_classroom_id
            FROM audits
           WHERE auditable_type = 'Avaliation'
             AND auditable_id = avaliation.id
             AND action = 'create';

          UPDATE avaliations
             SET classroom_id = correct_classroom_id
           WHERE id = avaliation.id;

          UPDATE recovery_diary_records
             SET classroom_id = correct_classroom_id
            FROM avaliation_recovery_diary_records
           WHERE avaliation_recovery_diary_records.avaliation_id = avaliation.id
             AND recovery_diary_records.id = avaliation_recovery_diary_records.recovery_diary_record_id;
        END LOOP;
      END$$;
    SQL
  end
end
