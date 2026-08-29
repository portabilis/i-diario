# Descarta os quadros de aula excedentes de cada turma/série e turno, mantendo o que tem mais
# células preenchidas — no empate, o de menor id. O descarte desce para as aulas e os dias da
# semana porque a migration roda em SQL e os callbacks `after_discard` do model não são acionados.
class DiscardDuplicatedLessonsBoards < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      CREATE TEMPORARY TABLE duplicated_lessons_boards ON COMMIT DROP AS
        SELECT ranked.id
        FROM (
          SELECT lessons_board.id,
                 row_number() OVER (
                   PARTITION BY lessons_board.classrooms_grade_id, lessons_board.period
                   ORDER BY cells.filled_cells DESC, lessons_board.id
                 ) AS position
          FROM lessons_boards lessons_board
          LEFT JOIN LATERAL (
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
        ) ranked
        WHERE ranked.position > 1
    SQL

    execute <<-SQL
      UPDATE lessons_board_lesson_weekdays weekday
         SET discarded_at = now()
        FROM lessons_board_lessons lesson
       WHERE weekday.lessons_board_lesson_id = lesson.id
         AND weekday.discarded_at IS NULL
         AND lesson.lessons_board_id IN (SELECT id FROM duplicated_lessons_boards)
    SQL

    execute <<-SQL
      UPDATE lessons_board_lessons
         SET discarded_at = now()
       WHERE discarded_at IS NULL
         AND lessons_board_id IN (SELECT id FROM duplicated_lessons_boards)
    SQL

    execute <<-SQL
      UPDATE lessons_boards
         SET discarded_at = now()
       WHERE id IN (SELECT id FROM duplicated_lessons_boards)
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
