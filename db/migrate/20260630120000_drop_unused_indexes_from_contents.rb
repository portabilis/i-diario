class DropUnusedIndexesFromContents < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  # Índices da tabela `contents` sem uso em produção (0 scans em todas as entidades).
  INDEXES = {
    'contents_description_gin_trgm_idx' =>
      'CREATE INDEX CONCURRENTLY IF NOT EXISTS contents_description_gin_trgm_idx ' \
      'ON contents USING gin (f_unaccent((description)::text) gin_trgm_ops)',
    'index_contents_on_created_at' =>
      'CREATE INDEX CONCURRENTLY IF NOT EXISTS index_contents_on_created_at ' \
      'ON contents USING btree (created_at)'
  }.freeze

  def up
    INDEXES.each_key do |index_name|
      execute "DROP INDEX CONCURRENTLY IF EXISTS #{index_name}"
    end
  end

  def down
    INDEXES.each_value do |create_statement|
      execute create_statement
    end
  end
end
