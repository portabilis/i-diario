class ReplaceGistWithGinOnContentsDocumentTokens < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def up
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS document_tokens_contents_gin_idx
      ON contents USING GIN (document_tokens);
    SQL

    execute "DROP INDEX CONCURRENTLY IF EXISTS document_tokens_contents_idx;"
  end

  def down
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS document_tokens_contents_idx
      ON contents USING GIST (document_tokens);
    SQL

    execute "DROP INDEX CONCURRENTLY IF EXISTS document_tokens_contents_gin_idx;"
  end
end
