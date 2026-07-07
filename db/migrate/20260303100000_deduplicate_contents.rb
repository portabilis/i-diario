class DeduplicateContents < ActiveRecord::Migration
  def up
    execute <<-SQL
      DO $$
      BEGIN
        -- Cria tabela temporaria com o mapeamento de cada duplicata para o seu id canonico (MIN)
        CREATE TEMP TABLE contents_dedup_map AS
        SELECT c.id AS duplicate_id, canon.canonical_id
          FROM contents c
          JOIN (
            SELECT MIN(id) AS canonical_id, description
              FROM contents
             GROUP BY description
            HAVING COUNT(*) > 1
          ) canon ON canon.description = c.description
                 AND c.id <> canon.canonical_id;

        -- Remove referencias duplicadas em contents_teaching_plans que violariam UNIQUE(content_id, teaching_plan_id)
        -- Caso 1: o canonico ja esta vinculado ao mesmo plano
        -- Caso 2: outra duplicata do mesmo canonico ja referencia o mesmo plano (mantém a de menor id)
        DELETE FROM contents_teaching_plans ctp
         USING contents_dedup_map m
         WHERE ctp.content_id = m.duplicate_id
           AND (
             EXISTS (
               SELECT 1 FROM contents_teaching_plans existing
                WHERE existing.teaching_plan_id = ctp.teaching_plan_id
                  AND existing.content_id = m.canonical_id
             )
             OR EXISTS (
               SELECT 1 FROM contents_teaching_plans other
                 JOIN contents_dedup_map m2 ON m2.duplicate_id = other.content_id
                WHERE other.teaching_plan_id = ctp.teaching_plan_id
                  AND m2.canonical_id = m.canonical_id
                  AND other.id < ctp.id
             )
           );

        -- Reparenta os restantes para o canonico
        UPDATE contents_teaching_plans ctp
           SET content_id = m.canonical_id
          FROM contents_dedup_map m
         WHERE ctp.content_id = m.duplicate_id;

        -- Remove referencias duplicadas em contents_lesson_plans (mesmo content_id + lesson_plan_id)
        DELETE FROM contents_lesson_plans clp
         USING contents_dedup_map m
         WHERE clp.content_id = m.duplicate_id
           AND (
             EXISTS (
               SELECT 1 FROM contents_lesson_plans existing
                WHERE existing.lesson_plan_id = clp.lesson_plan_id
                  AND existing.content_id = m.canonical_id
             )
             OR EXISTS (
               SELECT 1 FROM contents_lesson_plans other
                 JOIN contents_dedup_map m2 ON m2.duplicate_id = other.content_id
                WHERE other.lesson_plan_id = clp.lesson_plan_id
                  AND m2.canonical_id = m.canonical_id
                  AND other.id < clp.id
             )
           );

        UPDATE contents_lesson_plans clp
           SET content_id = m.canonical_id
          FROM contents_dedup_map m
         WHERE clp.content_id = m.duplicate_id;

        -- Remove referencias duplicadas em content_records_contents (mesmo content_id + content_record_id)
        DELETE FROM content_records_contents crc
         USING contents_dedup_map m
         WHERE crc.content_id = m.duplicate_id
           AND (
             EXISTS (
               SELECT 1 FROM content_records_contents existing
                WHERE existing.content_record_id = crc.content_record_id
                  AND existing.content_id = m.canonical_id
             )
             OR EXISTS (
               SELECT 1 FROM content_records_contents other
                 JOIN contents_dedup_map m2 ON m2.duplicate_id = other.content_id
                WHERE other.content_record_id = crc.content_record_id
                  AND m2.canonical_id = m.canonical_id
                  AND other.id < crc.id
             )
           );

        UPDATE content_records_contents crc
           SET content_id = m.canonical_id
          FROM contents_dedup_map m
         WHERE crc.content_id = m.duplicate_id;

        -- Remove referencias duplicadas em contents_content_records (mesmo content_id + content_record_id)
        DELETE FROM contents_content_records ccr
         USING contents_dedup_map m
         WHERE ccr.content_id = m.duplicate_id
           AND (
             EXISTS (
               SELECT 1 FROM contents_content_records existing
                WHERE existing.content_record_id = ccr.content_record_id
                  AND existing.content_id = m.canonical_id
             )
             OR EXISTS (
               SELECT 1 FROM contents_content_records other
                 JOIN contents_dedup_map m2 ON m2.duplicate_id = other.content_id
                WHERE other.content_record_id = ccr.content_record_id
                  AND m2.canonical_id = m.canonical_id
                  AND other.id < ccr.id
             )
           );

        UPDATE contents_content_records ccr
           SET content_id = m.canonical_id
          FROM contents_dedup_map m
         WHERE ccr.content_id = m.duplicate_id;

        -- Atualiza audits que referenciam duplicatas como auditable
        UPDATE audits
           SET auditable_id = m.canonical_id
          FROM contents_dedup_map m
         WHERE audits.auditable_type = 'Content'
           AND audits.auditable_id = m.duplicate_id;

        -- Atualiza audits que referenciam duplicatas como associated
        UPDATE audits
           SET associated_id = m.canonical_id
          FROM contents_dedup_map m
         WHERE audits.associated_type = 'Content'
           AND audits.associated_id = m.duplicate_id;

        -- Deleta os registros duplicados da tabela contents
        DELETE FROM contents
         USING contents_dedup_map m
         WHERE contents.id = m.duplicate_id;

        -- Remove tabela temporaria
        DROP TABLE contents_dedup_map;
      END$$;
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
