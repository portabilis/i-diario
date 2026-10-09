class AddIndexToLessonsBoardsOnClassroomsGradeId < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_lessons_boards_on_classrooms_grade_id_kept'.freeze

  def up
    # CONCURRENTLY deixa um índice INVALID para trás quando a criação falha, e a reexecução
    # morreria com "relation already exists". Como as migrations rodam por Entity, o DROP
    # antes é o que permite rodar de novo a entidade que falhou.
    execute "DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME}"

    execute <<-SQL
      CREATE INDEX CONCURRENTLY #{INDEX_NAME}
        ON lessons_boards (classrooms_grade_id)
        WHERE discarded_at IS NULL
    SQL
  end

  def down
    execute "DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME}"
  end
end
