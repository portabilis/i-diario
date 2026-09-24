# Garante um quadro de aula por turma/série e turno.
#
# O descarte dos excedentes e a criação do índice vivem na mesma migration porque, entre um e outro,
# a tela continua aceitando envios: um quadro duplicado criado nesse intervalo faria o
# `CREATE UNIQUE INDEX CONCURRENTLY` falhar e deixaria a Entity com o índice INVALID.
#
# Entre os quadros de uma mesma chave sobrevive o de mais células preenchidas; no empate, o alterado
# por último e depois o de menor id. Os `UPDATE` em massa pulam os callbacks `after_discard` (por isso
# a cascata desce à mão, dos dias para as aulas e daí para o quadro) e também a gravação em `audits`:
# o rastro do que esta migration descartou é o `discarded_at` compartilhado por todos os registros de
# uma mesma execução, que é também o critério para desfazê-la.
class DeduplicateAndIndexLessonsBoards < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  INDEX_NAME = 'idx_lessons_boards_unique_kept'.freeze

  def up
    discard_duplicated_lessons_boards

    # CONCURRENTLY deixa um índice INVALID para trás quando a criação falha, e a reexecução
    # morreria com "relation already exists". Como as migrations rodam por Entity, o DROP
    # antes é o que permite rodar de novo a entidade que falhou.
    execute "DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME}"

    execute <<-SQL
      CREATE UNIQUE INDEX CONCURRENTLY #{INDEX_NAME}
        ON lessons_boards (classrooms_grade_id, period)
        WHERE discarded_at IS NULL
    SQL
  end

  # Só o índice é removido: o descarte dos excedentes é desfeito pelo `discarded_at` da execução.
  def down
    execute "DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME}"
  end

  private

  def discard_duplicated_lessons_boards
    # `disable_ddl_transaction!` deixa cada `execute` em sua própria transação, e a tabela temporária
    # não sobreviveria de um para o outro. A transação explícita é o que a mantém viva e o que garante
    # que quadro, aulas e dias sejam descartados juntos.
    transaction do
      execute <<-SQL
        CREATE TEMPORARY TABLE duplicated_lessons_boards ON COMMIT DROP AS
          SELECT ranked.id
          FROM (
            SELECT lessons_board.id,
                   row_number() OVER (
                     PARTITION BY lessons_board.classrooms_grade_id, lessons_board.period
                     ORDER BY cells.filled_cells DESC, lessons_board.updated_at DESC, lessons_board.id
                   ) AS position
            FROM lessons_boards lessons_board
            LEFT JOIN LATERAL (
              -- Célula preenchida é o dia da semana ativo que aponta para um vínculo de professor.
              SELECT count(*) AS filled_cells
              FROM lessons_board_lessons lesson
              JOIN lessons_board_lesson_weekdays weekday
                ON weekday.lessons_board_lesson_id = lesson.id
               AND weekday.discarded_at IS NULL
               AND weekday.teacher_discipline_classroom_id IS NOT NULL
              WHERE lesson.lessons_board_id = lessons_board.id
                AND lesson.discarded_at IS NULL
            ) cells ON true
            WHERE lessons_board.discarded_at IS NULL
              -- `PARTITION BY` junta NULLs numa só partição, enquanto o índice único trata cada NULL
              -- como distinto. Sem este recorte, quadros de turmas diferentes sem `classrooms_grade_id`
              -- — o backfill de 2022 roda em SQL e não passa pela validação de presença — seriam
              -- descartados sem que o índice exigisse.
              AND lessons_board.classrooms_grade_id IS NOT NULL
              AND lessons_board.period IS NOT NULL
          ) ranked
          WHERE ranked.position > 1
      SQL

      execute <<-SQL
        UPDATE lessons_board_lesson_weekdays weekday
           SET discarded_at = now(), updated_at = now()
          FROM lessons_board_lessons lesson
         WHERE weekday.lessons_board_lesson_id = lesson.id
           AND weekday.discarded_at IS NULL
           AND lesson.lessons_board_id IN (SELECT id FROM duplicated_lessons_boards)
      SQL

      execute <<-SQL
        UPDATE lessons_board_lessons
           SET discarded_at = now(), updated_at = now()
         WHERE discarded_at IS NULL
           AND lessons_board_id IN (SELECT id FROM duplicated_lessons_boards)
      SQL

      execute <<-SQL
        UPDATE lessons_boards
           SET discarded_at = now(), updated_at = now()
         WHERE id IN (SELECT id FROM duplicated_lessons_boards)
      SQL
    end
  end
end
