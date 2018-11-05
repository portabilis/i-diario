class AlterActiveFieldOnDailyNoteStudentToNotNull < ActiveRecord::Migration
  def change
    execute <<-SQL
      DROP VIEW moved_***REMOVED***;
      DROP VIEW daily_note_statuses;
    SQL

    change_column(:daily_note_students, :active, :boolean, null: :false, default: :true)

    execute <<-SQL
      CREATE OR REPLACE VIEW moved_***REMOVED*** AS
        SELECT row_number() OVER () AS id,
            moviment.unity_id,
            moviment.material_id,
            sum(moviment.exit_quantity) AS exit_quantity,
            sum(moviment.entrance_quantity) AS entrance_quantity,
            max(moviment.entered_at) AS last_entered_at,
            max(moviment.entered_at_created_at) AS last_entered_at_created_at,
            max(moviment.exited_at) AS last_exited_at,
            max(moviment.exited_at_created_at) AS last_exited_at_created_at
          FROM ( SELECT me.origin_unity_id AS unity_id,
                    mei.material_id,
                    sum(mei.quantity) AS exit_quantity,
                    0 AS entrance_quantity,
                    max(me.exited_at) AS exited_at,
                    max(me.created_at) AS exited_at_created_at,
                    NULL::date AS entered_at,
                    NULL::date AS entered_at_created_at
                  FROM material_exit_items mei
                    JOIN ***REMOVED*** me ON mei.material_exit_id = me.id
                  GROUP BY me.origin_unity_id, mei.material_id
                UNION
                SELECT me.destination_unity_id AS unity_id,
                    mei.material_id,
                    0 AS exit_quantity,
                    sum(td_conversion_base.quantity) AS entrance_quantity,
                    NULL::date AS exited_at,
                    NULL::date AS exited_at_created_at,
                    max(me.entered_at) AS entered_at,
                    max(me.created_at) AS entered_at_created_at
                  FROM material_entrance_items mei
                    JOIN ***REMOVED*** me ON mei.material_entrance_id = me.id
                    JOIN ***REMOVED*** m ON mei.material_id = m.id AND m.active
                    JOIN ***REMOVED*** mu ON mu.id = mei.measuring_unit_id
                    JOIN ***REMOVED*** mu_base ON mu_base.id = m.measuring_unit_id
                    JOIN units_conversions uc ON uc.measuring_unit_id = mu.id AND uc.unit::text = mu.unit::text
                    JOIN units_conversions uc_base ON uc_base.measuring_unit_id = mu_base.id AND uc_base.unit::text = mu.unit::text,
                    LATERAL ( SELECT
                                CASE uc.calc
                                    WHEN 'm'::text THEN mei.quantity * uc.quantity
                                    WHEN 'd'::text THEN mei.quantity / uc.quantity
                                    ELSE NULL::numeric
                                END AS quantity) td_conversion,
                    LATERAL ( SELECT
                                CASE uc_base.calc
                                    WHEN 'm'::text THEN td_conversion.quantity / uc_base.quantity
                                    WHEN 'd'::text THEN td_conversion.quantity * uc_base.quantity
                                    ELSE NULL::numeric
                                END AS quantity) td_conversion_base
                  GROUP BY me.destination_unity_id, mei.material_id) moviment
          GROUP BY moviment.unity_id, moviment.material_id;

      CREATE OR REPLACE VIEW daily_note_statuses AS
        SELECT outer_daily_notes.id AS daily_note_id,
                CASE
                    WHEN (EXISTS ( SELECT daily_notes.id
                      FROM daily_notes
                        JOIN daily_note_students ON daily_notes.id = daily_note_students.daily_note_id
                      WHERE daily_note_students.note IS NULL AND daily_note_students.active = true AND NOT (EXISTS ( SELECT 1
                              FROM avaliation_exemptions
                              WHERE avaliation_exemptions.avaliation_id = daily_notes.avaliation_id AND avaliation_exemptions.student_id = daily_note_students.student_id)) AND daily_notes.id = outer_daily_notes.id)) THEN 'incomplete'::text
                    ELSE 'complete'::text
                END AS status
          FROM daily_notes outer_daily_notes;
    SQL
  end
end
