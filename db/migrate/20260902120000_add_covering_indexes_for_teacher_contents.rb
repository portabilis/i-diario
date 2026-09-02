# Índices que cobrem a busca dos conteúdos de um professor (Content.by_teacher_id) com Index Only Scan.
#
# A busca parte do professor e percorre content_records(teacher_id) -> content_records_contents(content_record_id)
# -> content_id, e o equivalente em contents_lesson_plans. Com índice só na chave estrangeira, o Postgres precisa
# visitar o heap de cada tabela para ler o id/content_id e, quando o professor tem milhares de registros, prefere
# varrer content_records_contents inteira. Com (fk, id) o percurso inteiro sai do índice.
#
# Os índices de coluna única substituídos ficam redundantes (o composto atende as mesmas consultas pelo prefixo)
# e são removidos para não pagar a escrita em dobro.
class AddCoveringIndexesForTeacherContents < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  INDEXES = [
    {
      table: 'content_records',
      name: 'idx_content_records_on_teacher_and_id',
      columns: 'teacher_id, id',
      replaces: 'index_content_records_on_teacher_id',
      replaces_columns: 'teacher_id'
    },
    {
      table: 'content_records_contents',
      name: 'idx_content_records_contents_on_record_and_content',
      columns: 'content_record_id, content_id',
      replaces: 'index_content_records_contents_on_content_record_id',
      replaces_columns: 'content_record_id'
    },
    {
      table: 'contents_lesson_plans',
      name: 'idx_contents_lesson_plans_on_plan_and_content',
      columns: 'lesson_plan_id, content_id',
      replaces: 'index_contents_lesson_plans_on_lesson_plan_id',
      replaces_columns: 'lesson_plan_id'
    }
  ].freeze

  def up
    INDEXES.each do |index|
      swap_index(
        table: index[:table],
        create_name: index[:name],
        create_columns: index[:columns],
        drop_name: index[:replaces]
      )
    end
  end

  def down
    INDEXES.each do |index|
      swap_index(
        table: index[:table],
        create_name: index[:replaces],
        create_columns: index[:replaces_columns],
        drop_name: index[:name]
      )
    end
  end

  private

  # O índice novo é criado antes de remover o antigo para a tabela nunca ficar sem índice na chave.
  # CONCURRENTLY deixa um índice INVALID para trás quando a criação falha e a reexecução morreria com
  # "relation already exists"; como as migrations rodam por Entity, o DROP antes é o que permite rodar
  # de novo a entidade que falhou.
  def swap_index(table:, create_name:, create_columns:, drop_name:)
    execute "DROP INDEX CONCURRENTLY IF EXISTS #{create_name}"
    execute "CREATE INDEX CONCURRENTLY #{create_name} ON #{table} (#{create_columns})"
    execute "DROP INDEX CONCURRENTLY IF EXISTS #{drop_name}"
  end
end
