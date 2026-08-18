# Reescreve as views materializadas do acompanhamento pedagógico.
#
# As definições anteriores produziam linhas duplicadas em massa: o JOIN com
# teacher_discipline_classrooms emitia uma linha por vínculo de disciplina do
# professor na turma (em vez de apenas responder se o vínculo existe) e o
# UNION ALL somava as mesmas linhas duas vezes. Os consumidores já descartavam
# as duplicatas com DISTINCT, então as views carregavam de 5 a 25 vezes mais
# linhas do que o necessário — além de colunas de texto (nomes de escola, turma
# e professor) que nenhum consumidor lê.
#
# As novas definições mantêm apenas as colunas consumidas, trocam o JOIN
# multiplicativo por EXISTS e deduplicam com GROUP BY. O índice único passa a
# permitir REFRESH MATERIALIZED VIEW CONCURRENTLY, que não bloqueia as leituras
# do dashboard durante a atualização. A coluna last_refresh sai das views e
# passa a ser registrada na tabela materialized_view_refreshes (um timestamp
# por view, em vez de um por linha — o que também inviabilizaria o diff do
# refresh concorrente).
class RecreatePedagogicalTrackingMaterializedViews < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      DROP MATERIALIZED VIEW mvw_frequency_by_school_classroom_teachers;

      CREATE MATERIALIZED VIEW mvw_frequency_by_school_classroom_teachers AS
      SELECT daily_frequencies.frequency_date,
             classrooms.unity_id,
             daily_frequencies.classroom_id,
             daily_frequencies.owner_teacher_id AS teacher_id
        FROM daily_frequencies
        JOIN classrooms
          ON classrooms.id = daily_frequencies.classroom_id
        JOIN unity_school_days
          ON unity_school_days.unity_id = classrooms.unity_id
         AND unity_school_days.school_day = daily_frequencies.frequency_date
        JOIN teachers
          ON teachers.id = daily_frequencies.owner_teacher_id
       WHERE EXISTS (
               SELECT 1
                 FROM teacher_discipline_classrooms tdc
                WHERE tdc.teacher_id = daily_frequencies.owner_teacher_id
                  AND tdc.classroom_id = daily_frequencies.classroom_id
                  AND tdc.discarded_at IS NULL
             )
       GROUP BY daily_frequencies.frequency_date,
                classrooms.unity_id,
                daily_frequencies.classroom_id,
                daily_frequencies.owner_teacher_id;

      CREATE UNIQUE INDEX idx_mvw_freq_unique
          ON mvw_frequency_by_school_classroom_teachers
             (unity_id, frequency_date, classroom_id, teacher_id);

      DROP MATERIALIZED VIEW mvw_content_record_by_school_classroom_teachers;

      CREATE MATERIALIZED VIEW mvw_content_record_by_school_classroom_teachers AS
      SELECT content_records.record_date,
             classrooms.unity_id,
             content_records.classroom_id,
             content_records.teacher_id
        FROM content_records
        JOIN classrooms
          ON classrooms.id = content_records.classroom_id
        JOIN unity_school_days
          ON unity_school_days.unity_id = classrooms.unity_id
         AND unity_school_days.school_day = content_records.record_date
        JOIN teachers
          ON teachers.id = content_records.teacher_id
       WHERE EXISTS (
               SELECT 1
                 FROM discipline_content_records dcr
                 JOIN teacher_discipline_classrooms tdc
                   ON tdc.teacher_id = content_records.teacher_id
                  AND tdc.classroom_id = content_records.classroom_id
                  AND tdc.discipline_id = dcr.discipline_id
                  AND tdc.discarded_at IS NULL
                WHERE dcr.content_record_id = content_records.id
             )
          OR EXISTS (
               SELECT 1
                 FROM knowledge_area_content_records kacr
                WHERE kacr.content_record_id = content_records.id
                  AND EXISTS (
                        SELECT 1
                          FROM teacher_discipline_classrooms tdc
                         WHERE tdc.teacher_id = content_records.teacher_id
                           AND tdc.classroom_id = content_records.classroom_id
                           AND tdc.discarded_at IS NULL
                      )
             )
       GROUP BY content_records.record_date,
                classrooms.unity_id,
                content_records.classroom_id,
                content_records.teacher_id;

      CREATE UNIQUE INDEX idx_mvw_content_unique
          ON mvw_content_record_by_school_classroom_teachers
             (unity_id, record_date, classroom_id, teacher_id);
    SQL

    # As views nascem populadas, mas a data exibida na tela passa a vir da
    # tabela de controle: sem este registro inicial o dashboard afirmaria que
    # não existem lançamentos até a primeira execução da rotina noturna.
    execute <<-SQL
      INSERT INTO materialized_view_refreshes (view_name, refreshed_at)
           VALUES ('mvw_frequency_by_school_classroom_teachers', now()),
                  ('mvw_content_record_by_school_classroom_teachers', now());
    SQL
  end

  def down
    execute <<-SQL
      DELETE FROM materialized_view_refreshes
            WHERE view_name IN ('mvw_frequency_by_school_classroom_teachers',
                                'mvw_content_record_by_school_classroom_teachers');
    SQL

    execute <<-SQL
      DROP MATERIALIZED VIEW mvw_frequency_by_school_classroom_teachers;

      CREATE MATERIALIZED VIEW mvw_frequency_by_school_classroom_teachers AS
      SELECT daily_frequencies.frequency_date AS frequency_date,
             unities.id AS unity_id,
             unities.name AS unity,
             classrooms.id AS classroom_id,
             classrooms.description AS classroom,
             teachers.id AS teacher_id,
             teachers.name AS teacher,
             now() AS last_refresh
        FROM daily_frequencies
        JOIN classrooms
          ON classrooms.id = daily_frequencies.classroom_id
        JOIN unities
          ON unities.id = classrooms.unity_id
        JOIN unity_school_days
          ON unity_school_days.unity_id = unities.id
         AND unity_school_days.school_day = daily_frequencies.frequency_date
        JOIN teachers
          ON teachers.id = daily_frequencies.owner_teacher_id
        JOIN teacher_discipline_classrooms
          ON teacher_discipline_classrooms.teacher_id = daily_frequencies.owner_teacher_id
         AND teacher_discipline_classrooms.classroom_id = daily_frequencies.classroom_id
         AND teacher_discipline_classrooms.discipline_id = daily_frequencies.discipline_id
         AND teacher_discipline_classrooms.discarded_at IS NULL
       WHERE daily_frequencies.discipline_id IS NOT NULL

       UNION ALL

      SELECT daily_frequencies.frequency_date AS frequency_date,
             unities.id AS unity_id,
             unities.name AS unity,
             classrooms.id AS classroom_id,
             classrooms.description AS classroom,
             teachers.id AS teacher_id,
             teachers.name AS teacher,
             now() AS last_refresh
        FROM daily_frequencies
        JOIN classrooms
          ON classrooms.id = daily_frequencies.classroom_id
        JOIN unities
          ON unities.id = classrooms.unity_id
        JOIN unity_school_days
          ON unity_school_days.unity_id = unities.id
         AND unity_school_days.school_day = daily_frequencies.frequency_date
        JOIN teachers
          ON teachers.id = daily_frequencies.owner_teacher_id
        JOIN teacher_discipline_classrooms
          ON teacher_discipline_classrooms.teacher_id = daily_frequencies.owner_teacher_id
         AND teacher_discipline_classrooms.classroom_id = daily_frequencies.classroom_id
         AND teacher_discipline_classrooms.discarded_at IS NULL;

      CREATE INDEX idx_mvw_freq_unity_date
          ON mvw_frequency_by_school_classroom_teachers (unity_id, frequency_date);

      DROP MATERIALIZED VIEW mvw_content_record_by_school_classroom_teachers;

      CREATE MATERIALIZED VIEW mvw_content_record_by_school_classroom_teachers AS
      SELECT content_records.id,
             content_records.record_date AS record_date,
             unities.id AS unity_id,
             unities.name AS unity,
             classrooms.id AS classroom_id,
             classrooms.description AS classroom,
             teachers.id AS teacher_id,
             teachers.name AS teacher,
             now() AS last_refresh
        FROM content_records
        JOIN classrooms
          ON classrooms.id = content_records.classroom_id
        JOIN unities
          ON unities.id = classrooms.unity_id
        JOIN unity_school_days
          ON unity_school_days.unity_id = unities.id
         AND unity_school_days.school_day = content_records.record_date
        JOIN teachers
          ON teachers.id = content_records.teacher_id
        JOIN discipline_content_records
          ON discipline_content_records.content_record_id = content_records.id
        JOIN teacher_discipline_classrooms
          ON teacher_discipline_classrooms.teacher_id = content_records.teacher_id
         AND teacher_discipline_classrooms.classroom_id = content_records.classroom_id
         AND teacher_discipline_classrooms.discipline_id = discipline_content_records.discipline_id
         AND teacher_discipline_classrooms.discarded_at IS NULL

      UNION ALL

      SELECT content_records.id,
             content_records.record_date AS record_date,
             unities.id AS unity_id,
             unities.name AS unity,
             classrooms.id AS classroom_id,
             classrooms.description AS classroom,
             teachers.id AS teacher_id,
             teachers.name AS teacher,
             now() AS last_refresh
        FROM content_records
        JOIN classrooms
          ON classrooms.id = content_records.classroom_id
        JOIN unities
          ON unities.id = classrooms.unity_id
        JOIN unity_school_days
          ON unity_school_days.unity_id = unities.id
         AND unity_school_days.school_day = content_records.record_date
        JOIN teachers
          ON teachers.id = content_records.teacher_id
        JOIN knowledge_area_content_records
          ON knowledge_area_content_records.content_record_id = content_records.id
        JOIN teacher_discipline_classrooms
          ON teacher_discipline_classrooms.teacher_id = content_records.teacher_id
         AND teacher_discipline_classrooms.classroom_id = content_records.classroom_id
         AND teacher_discipline_classrooms.discarded_at IS NULL;

      CREATE INDEX index_mvw_content_tracking_covering
          ON mvw_content_record_by_school_classroom_teachers
             (unity_id, record_date, classroom_id, teacher_id);
    SQL
  end
end
