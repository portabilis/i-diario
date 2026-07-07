class AddUniqueMd5IndexToContents < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    execute "CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS idx_contents_md5_description ON contents (md5(description));"
  end

  def down
    execute "DROP INDEX CONCURRENTLY IF EXISTS idx_contents_md5_description;"
  end
end
