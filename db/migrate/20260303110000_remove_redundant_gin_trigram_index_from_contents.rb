class RemoveRedundantGinTrigramIndexFromContents < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_contents_on_description_gin_trgm;"
  end

  def down
    execute <<-SQL
      CREATE INDEX CONCURRENTLY index_contents_on_description_gin_trgm
      ON contents USING gin (description gin_trgm_ops);
    SQL
  end
end
