class AddPgTrgmExtension < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      CREATE EXTENSION pg_trgm;
    SQL
  end
end
