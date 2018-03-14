class CreateUnaccentExtension < ActiveRecord::Migration
  def change
    execute <<-SQL
      CREATE EXTENSION unaccent;
    SQL
  end
end
