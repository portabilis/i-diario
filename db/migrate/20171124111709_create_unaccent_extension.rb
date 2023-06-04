class CreateUnaccentExtension < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      CREATE EXTENSION unaccent;
    SQL
  end
end
