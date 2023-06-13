class AddIndexToContents < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      CREATE INDEX contents_description_gin_trgm_idx ON contents
      USING gin (f_unaccent(description) gin_trgm_ops);
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX contents_description_gin_trgm_idx;
    SQL
  end
end
