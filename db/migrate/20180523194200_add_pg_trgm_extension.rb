class AddPgTrgmExtension < ActiveRecord::Migration
  def change
    execute <<-SQL
      CREATE EXTENSION pg_trgm;
    SQL
  end
end
