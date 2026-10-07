# A unificação de professores percorre os diários de frequência de cada professor pela chave
# owner_teacher_id (Teacher#daily_frequencies e o ReverterService). Sem índice na coluna, cada
# busca é um Seq Scan em daily_frequencies, uma das maiores tabelas do banco.
#
# CONCURRENTLY deixa um índice INVALID para trás quando a criação falha, e a reexecução morreria
# com "relation already exists"; como as migrations rodam por Entity, o DROP antes é o que permite
# rodar de novo a entidade que falhou.
class AddIndexToDailyFrequenciesOnOwnerTeacherId < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_daily_frequencies_on_owner_teacher_id'.freeze

  def up
    execute "DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME}"
    execute "CREATE INDEX CONCURRENTLY #{INDEX_NAME} ON daily_frequencies (owner_teacher_id)"
  end

  def down
    execute "DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME}"
  end
end
